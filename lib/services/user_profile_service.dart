import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const _nameKey = 'user_profile_name';
  static const _photoPathKey = 'user_profile_photo_path';
  static const _favoriteCasinoIdKey = 'user_favorite_casino_id';
  static const _birthdayKey = 'user_birthday';
  static const _themeModeKey = 'user_theme_mode';
  static const _distanceNotificationsKey = 'distance_notifications_enabled';
  static const _notificationsEnabledKey = 'user_notifications_enabled';
  // Usar la misma clave que el servicio de background para sincronización
  static const _locationTrackingEnabledKey = 'location_tracking_enabled';

  Future<User> loadUser(User fallback) async {
    final prefs = await SharedPreferences.getInstance();
    final storedName = prefs.getString(_nameKey);
    final storedPhotoPath = prefs.getString(_photoPathKey);
    String? storedFavoriteCasinoId;
    try {
      storedFavoriteCasinoId = prefs.getString(_favoriteCasinoIdKey);
    } catch (e) {
      // If it fails (e.g. was stored as int), try to read as int and convert
      try {
        final intId = prefs.getInt(_favoriteCasinoIdKey);
        if (intId != null) storedFavoriteCasinoId = intId.toString();
      } catch (_) {
        // If all fails, ignore
      }
    }
    final storedBirthdayIso = prefs.getString(_birthdayKey);
    final storedNotificationsEnabled = prefs.getBool(_notificationsEnabledKey);
    final storedLocationTrackingEnabled =
        prefs.getBool(_locationTrackingEnabledKey);

    DateTime? storedBirthday;
    if (storedBirthdayIso != null) {
      storedBirthday = DateTime.tryParse(storedBirthdayIso);
    }

    return fallback.copyWith(
      name: storedName ?? fallback.name,
      profileImageUrl: storedPhotoPath ?? fallback.profileImageUrl,
      favoriteCasinoId: storedFavoriteCasinoId ?? fallback.favoriteCasinoId,
      birthday: storedBirthday ?? fallback.birthday,
      notificationsEnabled:
          storedNotificationsEnabled ?? fallback.notificationsEnabled,
      locationTrackingEnabled:
          storedLocationTrackingEnabled ?? fallback.locationTrackingEnabled,
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

  Future<void> saveFavoriteCasinoId(String? casinoId) async {
    final prefs = await SharedPreferences.getInstance();
    if (casinoId != null) {
      await prefs.setString(_favoriteCasinoIdKey, casinoId);
    } else {
      await prefs.remove(_favoriteCasinoIdKey);
    }
  }

  Future<String?> loadFavoriteCasinoId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_favoriteCasinoIdKey);
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

  Future<void> setDistanceNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_distanceNotificationsKey, enabled);
  }

  Future<bool> areDistanceNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_distanceNotificationsKey) ?? false;
  }

  Future<void> saveNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<bool> loadNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> saveLocationTrackingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationTrackingEnabledKey, enabled);
  }

  Future<bool> loadLocationTrackingEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationTrackingEnabledKey) ?? true;
  }

  Future<void> savePoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_points', points);
  }

  Future<int> loadPoints(int defaultPoints) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_points') ?? defaultPoints;
  }
}
