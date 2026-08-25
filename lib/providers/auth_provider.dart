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

const _unsetFirebaseUser = Object();

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
    Object? firebaseUser = _unsetFirebaseUser,
    MembershipStatus? membershipStatus,
    bool? biometricEnabled,
    bool? requiresBiometric,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      firebaseUser: identical(firebaseUser, _unsetFirebaseUser)
          ? this.firebaseUser
          : firebaseUser as User?,
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
    final isInitialized = state.status != AuthStatus.unknown;

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
            isInitialized ? state.requiresBiometric : biometricEnabled,
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
        requiresBiometric:
            isInitialized ? state.requiresBiometric : biometricEnabled,
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

      final updates = <String, dynamic>{};

      final derivedName =
          (data['name'] as String? ?? user.displayName ?? '').trim();

      if (!data.containsKey('id')) updates['id'] = user.uid;
      if (!data.containsKey('email')) updates['email'] = user.email;

      if (!data.containsKey('name') && derivedName.isNotEmpty) {
        updates['name'] = derivedName;
      }
      final existingPhoto = data['profile_image_url'] as String?;
      if (existingPhoto == null || existingPhoto.isEmpty) {
        updates['profile_image_url'] = 'assets/images/logo-dreams.png';
      }

      final legacyDailyBonus = data['dailyBonus'];
      if (legacyDailyBonus is Map) {
        final legacyStreak = (legacyDailyBonus['streak'] as num?)?.toInt() ?? 0;
        final currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
        final currentLongest = (data['longestStreak'] as num?)?.toInt() ?? 0;
        if (legacyStreak > currentStreak) {
          updates['streak'] = legacyStreak;
          updates['longestStreak'] =
              legacyStreak > currentLongest ? legacyStreak : currentLongest;
          updates['lastVisit'] = FieldValue.serverTimestamp();
          updates['visitHistoryDates'] = [DateTime.now().toIso8601String()];
        }
        updates['dailyBonus'] = FieldValue.delete();
      }

      if (!data.containsKey('streak') && !updates.containsKey('streak')) {
        updates['streak'] = 0;
      }
      if (!data.containsKey('longestStreak') &&
          !updates.containsKey('longestStreak')) {
        final effectiveStreak =
            (updates['streak'] as num? ?? data['streak'] as num? ?? 0)
                .toInt();
        updates['longestStreak'] = effectiveStreak;
      }

      if (!data.containsKey('totalVisits')) updates['totalVisits'] = 0;
      if (!data.containsKey('contactConsent')) updates['contactConsent'] = true;

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

      // Timestamp único de creación del documento.
      if (!data.containsKey('createdAt')) {
        updates['createdAt'] = FieldValue.serverTimestamp();
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
      AppLogger.error('Firebase sign-in failed: ${e.code}', e);
      state = state.copyWith(errorMessage: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al iniciar sesión');
      return false;
    }
  }

  /// Register with email and password
  Future<bool> registerWithEmail(String email, String password, String name,
      {String? rut}) async {
    try {
      state = state.copyWith(errorMessage: null);

      // Clear any old cache from previous sessions/users
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      final user = credential.user;
      if (user != null) {
        final userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userRef.set({
          'id': user.uid,
          'uid': user.uid,
          'email': email,
          'name': name,
          'rut': rut ?? '',
          'level': 'blue',
          'points': 100, // Bono inicial de bienvenida
          'balance': 0,
          'streak': 0,
          'longestStreak': 0,
          'totalVisits': 0,
          'favoriteCasinoId': '4', // Dreams Coyhaique
          'profile_image_url': 'assets/images/logo-dreams.png',
          'isMember': true,
          'userType': 'member',
          'notifications_enabled': true,
          'location_tracking_enabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _ensureUserDocument(user);
      }

      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(errorMessage: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error al registrarse: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(errorMessage: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(
          errorMessage: 'Error al enviar correo de recuperación');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();

    // Clear all local cache on logout
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

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
      case 'invalid-credential':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'network-request-failed':
        return 'No se pudo conectar. Revisa tu conexión a internet';
      case 'operation-not-allowed':
        return 'El acceso por correo y contraseña no está habilitado';
      default:
        return 'No se pudo iniciar sesión ($code)';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
