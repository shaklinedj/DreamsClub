
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const _favoriteCasinoKey = 'favoriteCasino';

  static Future<void> setFavoriteCasino(int casinoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_favoriteCasinoKey, casinoId);
  }

  static Future<int?> getFavoriteCasino() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_favoriteCasinoKey);
  }

  static Future<void> clearFavoriteCasino() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoriteCasinoKey);
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool?> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }
}
