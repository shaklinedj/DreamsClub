
import 'dart:async';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
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
  final LocationService _locationService = LocationService();
  final CasinoService _casinoService = CasinoService();

  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();

    final int? favoriteCasinoId = prefs.getInt('favoriteCasino');
    final double? favoriteCasinoLat = prefs.getDouble('favoriteCasinoLat');
    final double? favoriteCasinoLng = prefs.getDouble('favoriteCasinoLng');

    try {
      // 1. Get current user location
      final position = await _locationService.getCurrentLocation().timeout(const Duration(seconds: 7));
      if (!mounted) return;

      // 2. If a favorite casino is saved, check the distance
      if (favoriteCasinoId != null && favoriteCasinoLat != null && favoriteCasinoLng != null) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          favoriteCasinoLat,
          favoriteCasinoLng,
        );

        // If distance is more than 20km, show a choice dialog
        if (distance > 20000) {
          _showFarFromFavoriteDialog(position, favoriteCasinoId);
        } else {
          // If close enough, go directly to the favorite
          context.go('/casinos/$favoriteCasinoId');
        }
      } else {
        // 3. If no favorite is saved, find the nearest and save it
        await _findAndSetNearestCasino(position);
      }
    } catch (e) {
      // 4. If location fails for any reason (timeout, permissions)
      if (!mounted) return;
      // Fallback: if a favorite exists, go there. Otherwise, go to the list.
      if (favoriteCasinoId != null) {
        context.go('/casinos/$favoriteCasinoId');
      } else {
        context.go('/casinos');
      }
    }
  }

  Future<void> _findAndSetNearestCasino(Position position) async {
    if (!mounted) return;
    final nearestCasino = await _casinoService.getNearestCasino(position.latitude, position.longitude);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('favoriteCasino', nearestCasino.id);
    await prefs.setDouble('favoriteCasinoLat', nearestCasino.latitud);
    await prefs.setDouble('favoriteCasinoLng', nearestCasino.longitud);

    if (mounted) {
      context.go('/casinos/${nearestCasino.id}');
    }
  }

  void _showFarFromFavoriteDialog(Position currentPosition, int favoriteCasinoId) {
    showDialog(
      context: context,
      barrierDismissible: false, // User must make a choice
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Estás lejos'),
          content: const Text('Hemos detectado que estás a más de 20km de tu casino favorito. ¿Qué deseas hacer?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Ir a mi favorito'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                context.go('/casinos/$favoriteCasinoId');
              },
            ),
            ElevatedButton(
              child: const Text('Buscar uno cercano'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                // Find nearest, save it as new favorite, and navigate
                _findAndSetNearestCasino(currentPosition);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Verificando tu ubicación...')
          ],
        ),
      ),
    );
  }
}
