import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const _nameKey = 'user_profile_name';
  static const _photoPathKey = 'user_profile_photo_path';
  static const _favoriteCasinoKey = 'user_favorite_casino';
  static const _birthdayKey = 'user_birthday';
  static const _themeModeKey = 'user_theme_mode';

  Future<User> loadUser(User fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString(_nameKey);
    final storedPhotoPath = prefs.getString(_photoPathKey);
    final storedFavoriteCasino = prefs.getString(_favoriteCasinoKey);
    final storedBirthdayIso = prefs.getString(_birthdayKey);

    DateTime? storedBirthday;
    if (storedBirthdayIso != null) {
      storedBirthday = DateTime.tryParse(storedBirthdayIso);
    }

    return fallback.copyWith(
      name: storedName ?? fallback.name,
      profileImageUrl: storedPhotoPath ?? fallback.profileImageUrl,
      favoriteCasino: storedFavoriteCasino ?? fallback.favoriteCasino,
      birthday: storedBirthday ?? fallback.birthday,
    );
  }

  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  Future<void> savePhotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoPathKey, path);
  }

  Future<void> saveFavoriteCasino(String casinoName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoriteCasinoKey, casinoName);
  }

  Future<void> saveBirthday(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_birthdayKey, date.toIso8601String());
  }

  Future<void> clearPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPathKey);
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    if (stored == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (element) => element.name == stored,
      orElse: () => ThemeMode.system,
    );
  }
}
