import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> recordPlay(String gameId) async {
    if (userId.isEmpty) return;
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_played_${userId}_$gameId', now.toIso8601String());

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
  // Isolate by email or rut, defaulting to empty if loading
  final userId = user.email.isNotEmpty ? user.email : (user.rut ?? '');
  return GameHistoryNotifier(userId);
});
