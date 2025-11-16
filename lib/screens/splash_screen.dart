
import 'dart:math';

import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/user_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';


class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _determineNextScreen();
  }

  Future<void> _determineNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    final favoriteCasinoId = await UserPreferences.getFavoriteCasino();
    final casinos = ref.read(casinosProvider).asData?.value;

    if (favoriteCasinoId != null && casinos != null) {
      try {
        final position = await _locationService.getCurrentLocation();
        final favoriteCasino = casinos.firstWhere((c) => c.id == favoriteCasinoId);
        final distance = _calculateDistance(position.latitude, position.longitude, favoriteCasino.latitud, favoriteCasino.longitud);

        if (distance > 20) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Estás lejos de tu casino favorito'),
                content: const Text('¿Quieres buscar casinos cercanos a tu ubicación actual?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      final closestCasino = _findClosestCasino(casinos, position);
                      context.go('/casinos/${closestCasino.id}');
                    },
                    child: const Text('Buscar cercanos'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/casinos/$favoriteCasinoId');
                    },
                    child: const Text('Ir a mi favorito'),
                  ),
                ],
              ),
            );
          }
          return;
        } 
      } catch (e) {
        // Si falla la geolocalización, simplemente ir al casino favorito
        if (mounted) context.go('/casinos/$favoriteCasinoId');
        return;
      }
    } 
    
    if (favoriteCasinoId != null) {
        if (mounted) context.go('/casinos/$favoriteCasinoId');
        return;
    }

    try {
      final position = await _locationService.getCurrentLocation();
      if (casinos != null && casinos.isNotEmpty) {
        final closestCasino = _findClosestCasino(casinos, position);
        if (mounted) context.go('/casinos/${closestCasino.id}');
      } else {
        if (mounted) context.go('/select-favorite');
      }
    } catch (e) {
      if (mounted) context.go('/select-favorite');
    }
  }

  Casino _findClosestCasino(List<Casino> casinos, Position position) {
    Casino closest = casinos.first;
    double minDistance = _calculateDistance(
      position.latitude,
      position.longitude,
      closest.latitud,
      closest.longitud,
    );

    for (var casino in casinos.skip(1)) {
      double distance = _calculateDistance(
        position.latitude,
        position.longitude,
        casino.latitud,
        casino.longitud,
      );
      if (distance < minDistance) {
        minDistance = distance;
        closest = casino;
      }
    }
    return closest;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 + cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo-dreams.png', width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
