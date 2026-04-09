import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Authentication state for the app
enum AuthStatus {
  /// Not determined yet
  unknown,

  /// User is not authenticated
  unauthenticated,

  /// User is authenticated with account (full access)
  authenticated,
}

/// User membership status
enum MembershipStatus {
  /// Not a Dreams member - needs to register at casino
  none,

  /// Has Dreams card - full access
  member,
}

class AuthState {
  final AuthStatus status;
  final User? firebaseUser;
  final MembershipStatus membershipStatus;
  final bool biometricEnabled;
  final bool requiresBiometric;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.firebaseUser,
    this.membershipStatus = MembershipStatus.none,
    this.biometricEnabled = false,
    this.requiresBiometric = false,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  bool get isMember => membershipStatus == MembershipStatus.member;

  /// Whether user has full access (member) or limited access (guest)
  bool get hasFullAccess => isMember;

  AuthState copyWith({
    AuthStatus? status,
    User? firebaseUser,
    MembershipStatus? membershipStatus,
    bool? biometricEnabled,
    bool? requiresBiometric,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      requiresBiometric: requiresBiometric ?? this.requiresBiometric,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<void> _init() async {
    // Initialize state immediately for users without Firebase Auth
    await _initializeState(_auth.currentUser);

    // Listen to auth state changes for future updates
    _auth.authStateChanges().listen((User? user) async {
      await _initializeState(user);
    });

    // Check biometric availability
    await _checkBiometricStatus();
  }

  Future<void> _initializeState(User? user) async {
    if (user != null) {
      // Ensure user profile doc exists (avoids downstream failures)
      await _ensureUserDocument(user);

      // Check if user is a member (has Dreams card)
      final membershipStatus = await _checkMembershipStatus(user.uid);
      final biometricEnabled = await _isBiometricEnabled();

      state = state.copyWith(
        status: AuthStatus.authenticated,
        firebaseUser: user,
        membershipStatus: membershipStatus,
        biometricEnabled: biometricEnabled,
        requiresBiometric:
            biometricEnabled, // Require auth on startup if enabled
      );
      AppLogger.info(
          'Auth state updated (Firebase user): biometricEnabled=$biometricEnabled, requiresBiometric=${state.requiresBiometric}');
    } else {
      final biometricEnabled = await _isBiometricEnabled();

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        firebaseUser: null,
        membershipStatus: MembershipStatus.none,
        biometricEnabled: biometricEnabled,
        requiresBiometric: biometricEnabled,
      );
      AppLogger.info(
          'Auth state updated (no Firebase): biometricEnabled=$biometricEnabled, requiresBiometric=${state.requiresBiometric}');
    }
  }

  Future<void> _ensureUserDocument(User user) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snap = await userRef.get();
      final data = snap.data() ?? <String, dynamic>{};

      final derivedName = (user.displayName ??
              data['name'] as String? ??
              data['displayName'] as String? ??
              '')
          .trim();
      final derivedPhotoUrl = (user.photoURL ??
              data['profile_image_url'] as String? ??
              data['photoURL'] as String?)
          ?.trim();

      final updates = <String, dynamic>{};

      if (!data.containsKey('id')) updates['id'] = user.uid;
      if (!data.containsKey('email')) updates['email'] = user.email;

      if (!data.containsKey('name') && derivedName.isNotEmpty) {
        updates['name'] = derivedName;
      }
      if (!data.containsKey('displayName') && derivedName.isNotEmpty) {
        updates['displayName'] = derivedName;
      }

      if (!data.containsKey('profile_image_url') &&
          derivedPhotoUrl != null &&
          derivedPhotoUrl.isNotEmpty) {
        updates['profile_image_url'] = derivedPhotoUrl;
      }
      if (!data.containsKey('photoURL') &&
          derivedPhotoUrl != null &&
          derivedPhotoUrl.isNotEmpty) {
        updates['photoURL'] = derivedPhotoUrl;
      }

      // Defaults for app logic
      if (!data.containsKey('level')) updates['level'] = 'blue';
      if (!data.containsKey('points')) updates['points'] = 0;
      if (!data.containsKey('balance')) updates['balance'] = 0;

      // Membership flags used by AuthNotifier
      if (!data.containsKey('userType')) updates['userType'] = 'registered';
      if (!data.containsKey('isMember')) updates['isMember'] = false;

      // User settings used elsewhere
      if (!data.containsKey('notifications_enabled')) {
        updates['notifications_enabled'] = true;
      }
      if (!data.containsKey('location_tracking_enabled')) {
        updates['location_tracking_enabled'] = true;
      }

      // Timestamps (keep both keys to support mixed schema)
      if (!data.containsKey('createdAt')) {
        updates['createdAt'] = FieldValue.serverTimestamp();
      }
      if (!data.containsKey('created_at')) {
        updates['created_at'] = FieldValue.serverTimestamp();
      }

      if (updates.isNotEmpty) {
        await userRef.set(updates, SetOptions(merge: true));
      }
    } catch (e) {
      AppLogger.error('Error ensuring user document', e);
    }
  }

  Future<MembershipStatus> _checkMembershipStatus(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null &&
            (data['userType'] == 'member' || data['isMember'] == true)) {
          return MembershipStatus.member;
        }
      }
      return MembershipStatus
          .none; // Default to none (Guest/Registered but not Member)
    } catch (e) {
      AppLogger.error('Error checking membership status', e);
      return MembershipStatus.none;
    }
  }

  Future<bool> _isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canAuthenticate && isDeviceSupported) {
        final biometrics = await _localAuth.getAvailableBiometrics();
        AppLogger.info('Available biometrics: $biometrics');
      }
    } catch (e) {
      AppLogger.error('Error checking biometrics', e);
    }
  }

  // ============ Authentication Methods ============

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(errorMessage: null);

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = _auth.currentUser;
      if (user != null) {
        await _ensureUserDocument(user);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(errorMessage: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al iniciar sesión');
      return false;
    }
  }

  /// Register with email and password
  Future<bool> registerWithEmail(
      String email, String password, String name) async {
    try {
      state = state.copyWith(errorMessage: null);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      final user = credential.user;
      if (user != null) {
        await _ensureUserDocument(user);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(errorMessage: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al registrarse');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('is_guest_session');

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      firebaseUser: null,
      membershipStatus: MembershipStatus.none,
    );
  }

  // ============ Biometric Authentication ============

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      AppLogger.info('Attempting to enable biometric...');
      final authenticated = await _localAuth.authenticate(
        localizedReason:
            'Verifica tu identidad para activar la autenticación biométrica',
        // Note: biometricOnly defaults to false, allowing PIN/Pattern fallback
      );

      AppLogger.info('Biometric authentication result: $authenticated');

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        AppLogger.info('Biometric saved to SharedPreferences: true');

        state = state.copyWith(
          biometricEnabled: true,
          requiresBiometric: false, // Already authenticated to enable it
        );
        AppLogger.info(
            'State updated: biometricEnabled=${state.biometricEnabled}');
      }

      return authenticated;
    } catch (e) {
      AppLogger.error('Error enabling biometric', e);
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', false);
    state = state.copyWith(biometricEnabled: false);
  }

  /// Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      final success = await _localAuth.authenticate(
        localizedReason: 'Usa tu huella o PIN para continuar',
      );

      if (success) {
        state = state.copyWith(requiresBiometric: false);
      }

      return success;
    } catch (e) {
      AppLogger.error('Biometric authentication failed', e);
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      state =
          state.copyWith(errorMessage: 'Error al enviar email de recuperación');
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      default:
        return 'Error de autenticación';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
