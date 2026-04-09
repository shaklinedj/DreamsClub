import 'dart:convert';
import 'dart:async';
import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _defaultUser = User(
  name: 'Hernan Laurel',
  email: 'hernan.laurel@gmail.com',
  rut: '15516354-2',
  pin: '1111',
  profileImageUrl: 'assets/images/perfil_imagen.png',
  level: UserLevel.black,
  points: 95000,
  balance: 5550,
  birthday: DateTime(1982, 10, 1),
  isAdmin: true,
);

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

// DEBUG: Must match the UID used in Cloud Function (index.js line 50)
const String _debugUid = 'debug-hernan-laurel';

// Key for caching user snapshot
const String _userCacheKey = 'user_snapshot_cache';

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  final service = ref.watch(userProfileServiceProvider);
  final authState = ref.watch(authProvider);
  // Use Firebase UID if logged in, otherwise use debug UID
  final uid = authState.firebaseUser?.uid ?? _debugUid;
  return UserNotifier(service, _defaultUser, uid);
});

class UserNotifier extends StateNotifier<User> {
  UserNotifier(this._storage, this._defaultUser, this._uid)
      : super(_defaultUser) {
    _initWithCacheThenSync();
  }

  final UserProfileService _storage;
  final User _defaultUser;
  final String _uid;
  StreamSubscription? _userSubscription;

  /// Initialize: Load cache first for instant UI, then sync with Firestore
  Future<void> _initWithCacheThenSync() async {
    // 1. Load from cache immediately (offline-first)
    await _loadFromCache();
    
    // 2. Start realtime listener to Firestore (will update cache when data arrives)
    _initRealtimeListener();
  }

  /// Load user data from local cache (SharedPreferences)
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_userCacheKey);
      
      if (cached != null) {
        final map = json.decode(cached) as Map<String, dynamic>;
        final user = User.fromMap(map);
        if (mounted) {
          state = user;
          AppLogger.info('📦 Loaded user from cache: ${user.name}');
        }
      } else {
        // No cache, use default
        AppLogger.info('📦 No cache found, using defaults');
      }
    } catch (e) {
      AppLogger.error('Error loading from cache', e);
    }
  }

  /// Save current user state to local cache
  Future<void> _saveToCache(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = user.toMap();
      await prefs.setString(_userCacheKey, json.encode(map));
      AppLogger.debug('💾 User snapshot cached');
    } catch (e) {
      AppLogger.error('Error saving to cache', e);
    }
  }

  void _initRealtimeListener() {
    try {
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          try {
            final user = User.fromMap(snapshot.data()!);
            if (mounted) {
              state = user;
              // Save to cache for offline use
              _saveToCache(user);
            }
            AppLogger.info('🔄 User synced from Firestore: streak=${user.streak}, visits=${user.totalVisits}');
          } catch (e) {
            AppLogger.error("Error parsing user data", e);
          }
        }
      }, onError: (e) {
        AppLogger.error("Error listening to user updates (will use cache)", e);
      });
    } catch (e) {
      AppLogger.error("Failed to start Firestore listener", e);
    }
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // Helper to update Firestore
  Future<void> _updateFirestore(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateName(String newName) async {
    // Optimistic update
    state = state.copyWith(name: newName);
    await _saveToCache(state);
    await _storage.saveName(newName);
    await _updateFirestore({'name': newName});
  }

  Future<void> updateProfileImage(String newPath) async {
    state = state.copyWith(profileImageUrl: newPath);
    await _saveToCache(state);
    await _storage.savePhotoPath(newPath);
    await _updateFirestore({'profile_image_url': newPath});
  }

  Future<void> resetProfileImage() async {
    state = state.copyWith(profileImageUrl: _defaultUser.profileImageUrl);
    await _saveToCache(state);
    await _storage.clearPhotoPath();
    await _updateFirestore({'profile_image_url': _defaultUser.profileImageUrl});
  }

  Future<void> updateLevel(UserLevel newLevel) async {
    state = state.copyWith(level: newLevel);
    await _saveToCache(state);
    await _updateFirestore({'level': newLevel.name});
  }

  Future<void> updateFavoriteCasino(String? casinoId) async {
    state = state.copyWith(favoriteCasinoId: casinoId);
    await _saveToCache(state);
    await _storage.saveFavoriteCasinoId(casinoId);
    await _updateFirestore({'favoriteCasinoId': casinoId});
  }

  Future<void> updateBirthday(DateTime? date) async {
    state = state.copyWith(birthday: date);
    await _saveToCache(state);
    if (date != null) {
      await _storage.saveBirthday(date);
      await _updateFirestore({'birthday': date.toIso8601String()});
    }
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveToCache(state);
    await _storage.saveNotificationsEnabled(enabled);
    await _updateFirestore({'notifications_enabled': enabled});
  }

  Future<void> updateLocationTracking(bool enabled) async {
    state = state.copyWith(locationTrackingEnabled: enabled);
    await _saveToCache(state);
    await _storage.saveLocationTrackingEnabled(enabled);
    await _updateFirestore({'location_tracking_enabled': enabled});
  }

  Future<void> addPoints(int points) async {
    final newPoints = state.points + points;
    state = state.copyWith(points: newPoints);
    await _saveToCache(state);
    await _storage.savePoints(newPoints);
    await _updateFirestore({'points': newPoints});
  }

  Future<void> setPoints(int points) async {
    state = state.copyWith(points: points);
    await _saveToCache(state);
    await _storage.savePoints(points);
    await _updateFirestore({'points': points});
  }
}
