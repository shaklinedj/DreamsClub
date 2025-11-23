import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _defaultUser = User(
  name: 'Usuario Demo',
  email: 'demo@dreamclub.com',
  profileImageUrl: 'assets/images/perfil_imagen.png',
  level: UserLevel.blue,
  points: 5000,
  balance: 150000,
);

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  final service = ref.watch(userProfileServiceProvider);
  return UserNotifier(service, _defaultUser);
});

class UserNotifier extends StateNotifier<User> {
  UserNotifier(this._storage, this._defaultUser) : super(_defaultUser) {
    _loadUser();
  }

  final UserProfileService _storage;
  final User _defaultUser;

  Future<void> _loadUser() async {
    final stored = await _storage.loadUser(_defaultUser);
    if (mounted) {
      state = stored;
    }
  }

  Future<void> updateName(String newName) async {
    state = state.copyWith(name: newName);
    await _storage.saveName(newName);
  }

  Future<void> updateProfileImage(String newPath) async {
    state = state.copyWith(profileImageUrl: newPath);
    await _storage.savePhotoPath(newPath);
  }

  Future<void> resetProfileImage() async {
    state = state.copyWith(profileImageUrl: _defaultUser.profileImageUrl);
    await _storage.clearPhotoPath();
  }

  Future<void> updateLevel(UserLevel newLevel) async {
    state = state.copyWith(level: newLevel);
    // In a real app, this might save to storage or backend
  }

  Future<void> updateFavoriteCasino(String? casino) async {
    state = state.copyWith(favoriteCasino: casino);
    if (casino != null) {
      await _storage.saveFavoriteCasino(casino);
    }
  }

  Future<void> updateBirthday(DateTime? date) async {
    state = state.copyWith(birthday: date);
    if (date != null) {
      await _storage.saveBirthday(date);
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final service = ref.watch(userProfileServiceProvider);
  return ThemeModeNotifier(service);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    _load();
  }

  final UserProfileService _storage;

  Future<void> _load() async {
    final stored = await _storage.loadThemeMode();
    if (mounted) state = stored;
  }

  Future<void> update(ThemeMode mode) async {
    state = mode;
    await _storage.saveThemeMode(mode);
  }
}
