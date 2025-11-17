import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _defaultUser = User(
  name: 'John Doe',
  email: 'john.doe@email.com',
  profileImageUrl: 'assets/images/perfil_imagen.png',
  level: UserLevel.black,
  points: 125300,
  balance: 750.50,
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
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
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
