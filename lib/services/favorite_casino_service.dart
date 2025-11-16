import 'package:shared_preferences/shared_preferences.dart';

class FavoriteCasinoService {
  static const String _favoriteCasinoKey = 'favoriteCasino';

  Future<void> setFavoriteCasinoId(int casinoId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_favoriteCasinoKey, casinoId);
  }

  Future<int?> getFavoriteCasino() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_favoriteCasinoKey);
  }
}
