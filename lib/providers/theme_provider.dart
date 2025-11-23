import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final service = ref.watch(userProfileServiceProvider);
  return ThemeModeNotifier(service);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    _loadTheme();
  }

  final UserProfileService _storage;

  Future<void> _loadTheme() async {
    final stored = await _storage.loadThemeMode();
    if (mounted) state = stored;
  }

  Future<void> update(ThemeMode mode) async {
    state = mode;
    await _storage.saveThemeMode(mode);
  }
}
