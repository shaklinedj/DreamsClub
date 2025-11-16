
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _startNavigationLogic();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startNavigationLogic() async {
    // Start a 4-second timer as a fallback.
    _timer = Timer(const Duration(seconds: 4), _navigate);

    // Attempt to speed up navigation by getting location permission early.
    await _handleLocation();
  }

  Future<void> _handleLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; // Fallback to timer

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return; // Fallback to timer
        }
      }

      if (permission == LocationPermission.deniedForever) return; // Fallback to timer

      // Permissions are granted, we can try to navigate faster.
      if (_timer?.isActive ?? false) {
        _timer?.cancel();
        _navigate();
      }
    } catch (e) {
      // If any error occurs, just fallback to the timer.
    }
  }

  Future<void> _navigate() async {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    final prefs = await SharedPreferences.getInstance();
    final favoriteCasinoId = prefs.getInt('favoriteCasino');

    if (mounted) {
      if (favoriteCasinoId != null) {
        context.go('/casino/$favoriteCasinoId');
      } else {
        context.go('/casinos');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
