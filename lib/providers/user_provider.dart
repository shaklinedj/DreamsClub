import 'dart:convert';
import 'dart:async';
import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _defaultUser = User(
  name: 'Cargando...',
  email: '',
  rut: '',
  pin: '',
  profileImageUrl: '',
  level: UserLevel.blue,
  points: 0,
  balance: 0,
  isAdmin: false,
);

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

const String _userCacheKeyPrefix = 'user_snapshot_cache_';

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  final service = ref.watch(userProfileServiceProvider);
  // Only watch the firebase user's UID to prevent provider recreation when other auth state properties change.
  final uid =
      ref.watch(authProvider.select((state) => state.firebaseUser?.uid));
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserNotifier(service, _defaultUser, uid ?? '', prefs);
});

class UserNotifier extends StateNotifier<User> {
  UserNotifier(this._storage, this._defaultUser, this._uid, this._prefs)
      : super(_defaultUser) {
    if (_uid.isNotEmpty) {
      _initFromCacheSynchronously();
      _initWithCacheThenSync();
    }
  }

  final UserProfileService _storage;
  final User _defaultUser;
  final String _uid;
  final SharedPreferences _prefs;
  StreamSubscription? _userSubscription;

  void _initFromCacheSynchronously() {
    try {
      final cached = _prefs.getString('$_userCacheKeyPrefix$_uid');
      if (cached != null) {
        final map = json.decode(cached) as Map<String, dynamic>;
        state = User.fromMap(map);
        AppLogger.info('📦 Loaded user synchronously from cache: ${state.name}');
      } else {
        // Fallback: check if we have a separate cached streak or default
        final cachedStreak = _prefs.getInt('cached_user_streak');
        if (cachedStreak != null) {
          state = _defaultUser.copyWith(streak: cachedStreak);
          AppLogger.info('📦 Restored cached streak synchronously: $cachedStreak');
        }
      }
    } catch (e) {
      AppLogger.error('Error loading from cache synchronously', e);
    }
  }

  /// Initialize: Firestore is the source of truth. Cache is only a fallback.
  Future<void> _initWithCacheThenSync() async {
    await _loadFromFirestore(fallbackToCache: false);
    _initRealtimeListener();
  }

  Future<void> _loadFromFirestore({bool fallbackToCache = true}) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();

      if (doc.exists && doc.data() != null) {
        final user = User.fromMap(doc.data()!);
        if (mounted) {
          state = user;
        }
        await _saveToCache(user);
        AppLogger.info('📥 Loaded user from Firestore: ${user.name}');
        return;
      }

      // A successful read with no document is authoritative. Do not resurrect
      // an old local snapshot in this case.
      if (mounted) {
        state = _defaultUser;
      }
      return;
    } catch (e) {
      AppLogger.error('Error loading user from Firestore', e);
    }

    if (fallbackToCache) {
      await _loadFromCache();
    }
  }

  /// Load user data from local cache (SharedPreferences)
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_userCacheKeyPrefix$_uid');

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
      await prefs.setString('$_userCacheKeyPrefix$_uid', json.encode(map));
      await prefs.setInt('cached_user_streak', user.streak);

      // Save global "last user profile" for login screen recovery
      if (user.email.isNotEmpty) {
        await prefs.setString('last_logged_in_email', user.email);
        await prefs.setString('last_logged_in_name', user.name);
        await prefs.setString('last_logged_in_photo', user.profileImageUrl);
      }

      AppLogger.debug('💾 User snapshot & streak (${user.streak}d) cached');
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
            final data = snapshot.data()!;
            final user = User.fromMap(data);
            if (mounted) {
              state = user;
              // Save to cache for offline use
              _saveToCache(user);
            }

            // Self-correct isPresentToday if lastVisit was on a different day
            final lastVisitTimestamp = data['lastVisit'] as Timestamp?;
            final isPresentToday = data['isPresentToday'] as bool? ?? false;

            if (isPresentToday && lastVisitTimestamp != null) {
              final lastVisitDate = lastVisitTimestamp.toDate();
              final now = DateTime.now();
              final isSameDay = lastVisitDate.year == now.year &&
                  lastVisitDate.month == now.month &&
                  lastVisitDate.day == now.day;

              if (!isSameDay) {
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid)
                    .update({'isPresentToday': false});
              }
            }
            AppLogger.info(
                '🔄 User synced from Firestore: streak=${user.streak}, visits=${user.totalVisits}');
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

  Future<void> updateProfileDetails({
    required String name,
    required bool wantsContact,
    required String? phoneNumber,
  }) async {
    state = state.copyWith(
      name: name,
      wantsContact: wantsContact,
      phoneNumber: phoneNumber,
    );
    await _saveToCache(state);
    await _storage.saveName(name);
    await _updateFirestore({
      'name': name,
      'contactConsent': wantsContact,
      'phoneNumber': phoneNumber,
    });
  }

  Future<void> updateProfileImage(String newPath) async {
    state = state.copyWith(profileImageUrl: newPath);
    await _saveToCache(state);
    await _storage.savePhotoPath(newPath);
    await _updateFirestore({'profile_image_url': newPath});

    // Sync the new avatar across the database (e.g., comments)
    await _syncProfileAcrossDatabase(newPath);
  }

  /// Updates the user's avatar in denormalized collections (like comments and posts)
  Future<void> _syncProfileAcrossDatabase(String newAvatarUrl) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      int totalUpdates = 0;
      final targetUserId = _uid.isNotEmpty ? _uid : state.email;

      // 1. Sync comments authored by user
      try {
        final commentsQuery = await FirebaseFirestore.instance
            .collectionGroup('comments')
            .where('userId', isEqualTo: targetUserId)
            .get();

        for (var doc in commentsQuery.docs) {
          batch.update(doc.reference, {'userAvatar': newAvatarUrl});
          totalUpdates++;
        }
      } catch (_) {
        // Index exemption pending in Firestore console
      }

      // 3. Sync top-level coyhaique_posts authored by user (does not require collectionGroup index)
      try {
        final topLevelPosts = await FirebaseFirestore.instance
            .collection('coyhaique_posts')
            .where('userEmail', isEqualTo: state.email)
            .get();

        for (var doc in topLevelPosts.docs) {
          batch.update(doc.reference, {'userAvatar': newAvatarUrl});
          totalUpdates++;
        }
      } catch (_) {}

      if (totalUpdates > 0) {
        await batch.commit();
        AppLogger.info(
            '✅ Avatar de usuario sincronizado en $totalUpdates documentos.');
      }
    } catch (e) {
      AppLogger.debug('Sincronización de avatar completada.');
    }
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

  Future<void> setStreak(int newStreak) async {
    state = state.copyWith(streak: newStreak);
    await _saveToCache(state);
    await _updateFirestore({
      'streak': newStreak,
      'lastVisit': FieldValue.serverTimestamp(),
      'isPresentToday': true,
    });
  }

  Future<void> setTotalVisits(int newVisits) async {
    state = state.copyWith(totalVisits: newVisits);
    await _saveToCache(state);
    await _updateFirestore({'totalVisits': newVisits});
  }
}
