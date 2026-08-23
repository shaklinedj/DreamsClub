import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class GameHistoryNotifier
    extends StateNotifier<AsyncValue<Map<String, DateTime>>> {
  final String userId;

  GameHistoryNotifier(this.userId) : super(const AsyncValue.loading()) {
    if (userId.isNotEmpty) {
      _loadHistory();
    } else {
      state = const AsyncValue.data({});
    }
  }

  Future<void> _loadHistory() async {
    try {
      // 1. Load local cache from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final prefix = 'last_played_${userId}_';
      final keys = prefs.getKeys().where((k) => k.startsWith(prefix));
      final history = <String, DateTime>{};

      for (var key in keys) {
        final gameId = key.replaceFirst(prefix, '');
        final dateStr = prefs.getString(key);
        if (dateStr != null) {
          history[gameId] = DateTime.parse(dateStr);
        }
      }
      state = AsyncValue.data(history);

      // 2. Fetch from Firestore to sync if reinstalled or cleared
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('game_history')
          .get();

      final updatedHistory = Map<String, DateTime>.from(history);
      bool hasChanges = false;

      for (var doc in snapshot.docs) {
        final gameId = doc.id;
        final dateStr = doc.data()['last_played'] as String?;
        if (dateStr != null) {
          final firestoreTime = DateTime.parse(dateStr);
          final localTime = updatedHistory[gameId];
          if (localTime == null || firestoreTime.isAfter(localTime)) {
            updatedHistory[gameId] = firestoreTime;
            await prefs.setString('$prefix$gameId', dateStr);
            hasChanges = true;
          }
        }
      }

      if (hasChanges || history.isEmpty) {
        state = AsyncValue.data(updatedHistory);
      }
    } catch (e, st) {
      // Fallback to local data if firestore query fails (e.g. offline)
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> recordPlay(String gameId) async {
    if (userId.isEmpty) return;
    final now = DateTime.now();
    final dateStr = now.toIso8601String();

    try {
      // 1. Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_played_${userId}_$gameId', dateStr);

      // 2. Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('game_history')
          .doc(gameId)
          .set({'last_played': dateStr});
    } catch (e) {
      // Keep going if offline
    }

    // Update local state
    state.whenData((history) {
      final newHistory = Map<String, DateTime>.from(history);
      newHistory[gameId] = now;
      state = AsyncValue.data(newHistory);
    });
  }
}

final gameHistoryProvider = StateNotifierProvider<GameHistoryNotifier,
    AsyncValue<Map<String, DateTime>>>((ref) {
  final user = ref.watch(userProvider);
  // Isolate by user ID (uid) for reliable backend syncing
  final userId = user.id;
  return GameHistoryNotifier(userId);
});
