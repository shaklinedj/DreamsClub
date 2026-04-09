import 'package:shared_preferences/shared_preferences.dart';

enum DailyGameType { slotMachine, dreamsMania }

/// Service to manage alternating daily games (Slot Machine / Dreams Mania)
/// Only shows game on first app open of the day when inside a casino
class DailyGameService {
  static const _lastGameDateKey = 'daily_game_last_date';
  static const _lastGameTypeKey = 'daily_game_last_type';

  /// Check if a game should be shown
  /// Returns the game type to show, or null if already played today
  static Future<DailyGameType?> getGameToShow() async {
    final prefs = await SharedPreferences.getInstance();

    final lastDateStr = prefs.getString(_lastGameDateKey);
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    // Check if already shown today
    if (lastDateStr == todayStr) {
      return null; // Already played today
    }

    // Determine which game to show (alternate)
    final lastGameTypeStr = prefs.getString(_lastGameTypeKey);
    DailyGameType nextGame;

    if (lastGameTypeStr == 'slotMachine') {
      nextGame = DailyGameType.dreamsMania;
    } else {
      nextGame = DailyGameType.slotMachine;
    }

    return nextGame;
  }

  /// Mark the game as played for today
  static Future<void> markGamePlayed(DailyGameType type) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    await prefs.setString(_lastGameDateKey, todayStr);
    await prefs.setString(_lastGameTypeKey,
        type == DailyGameType.slotMachine ? 'slotMachine' : 'dreamsMania');
  }

  /// Check if enough time has passed (24+ hours) since last game
  static Future<bool> hasEnoughTimePassed() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_lastGameDateKey);

    if (lastDateStr == null) {
      return true; // First time
    }

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';

    return lastDateStr != todayStr;
  }
}
