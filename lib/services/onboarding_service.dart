import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _keyFirstLaunch = 'is_first_launch';
  static const String _keyLocationSetup = 'location_setup_completed';

  /// Check if this is the first time the app is launched
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }

  /// Mark that the app has been launched before
  Future<void> completeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }

  /// Check if location setup has been completed
  Future<bool> isLocationSetupCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLocationSetup) ?? false;
  }

  /// Mark location setup as completed
  Future<void> completeLocationSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLocationSetup, true);
  }

  /// Reset onboarding state (for testing)
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFirstLaunch);
    await prefs.remove(_keyLocationSetup);
  }
}
