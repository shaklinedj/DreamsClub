import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameHistoryNotifier
    extends StateNotifier<AsyncValue<Map<String, DateTime>>> {
  GameHistoryNotifier() : super(const AsyncValue.loading()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('last_played_'));
      final history = <String, DateTime>{};

      for (var key in keys) {
        final gameId = key.replaceFirst('last_played_', '');
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
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_played_$gameId', now.toIso8601String());

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
  return GameHistoryNotifier();
});
