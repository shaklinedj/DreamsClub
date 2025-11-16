
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
    // Start a 4-second timer
    _timer = Timer(const Duration(seconds: 4), _navigate);

    // Request location permission and get location
    await _requestLocationAndNavigate();
  }

  Future<void> _requestLocationAndNavigate() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the 
      // App to enable the location services.
       _navigate(); // Navigate after the timer or if location is disabled
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, navigate after timeout
        _navigate();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      _navigate();
      return;
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
       await Geolocator.getCurrentPosition();
       // If we get the location before the timer, navigate
       if(_timer?.isActive ?? false) {
          _timer?.cancel();
         _navigate();
       }
    } catch (e) {
       // If there is an error getting the location, navigate after timeout
       _navigate();
    }
  }


  Future<void> _navigate() async {
    if (!mounted) return;

    // Check for a favorite casino
    final prefs = await SharedPreferences.getInstance();
    final favoriteCasinoId = prefs.getInt('favoriteCasino');

    if (!mounted) return;

    if (favoriteCasinoId != null) {
      // Navigate to the favorite casino's detail screen
      context.go('/casino/$favoriteCasinoId');
    } else {
      // Navigate to the casino selection screen
      context.go('/casinos');
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
