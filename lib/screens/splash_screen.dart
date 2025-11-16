
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/casino_data.dart';
import '../models/casino.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _determineInitialRoute();
  }

  Future<void> _determineInitialRoute() async {
    // Intenta obtener el casino más cercano con un tiempo de espera de 7 segundos.
    try {
      final position = await _determinePosition().timeout(const Duration(seconds: 7));
      if (!mounted) return;

      final nearestCasino = _findNearestCasino(position);
      if (nearestCasino != null) {
        // Si se encuentra, guárdalo y navega a él.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('favoriteCasino', nearestCasino.id);
        if (mounted) {
          context.go('/casino/${nearestCasino.id}');
        }
        return;
      }
    } catch (e) {
      // Si falla la geolocalización o se agota el tiempo, continúa con el flujo normal.
    }

    // Si no se pudo obtener la ubicación, busca un favorito guardado.
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final favoriteCasinoId = prefs.getInt('favoriteCasino');

    if (mounted) {
      if (favoriteCasinoId != null) {
        context.go('/casino/$favoriteCasinoId');
      } else {
        // Como último recurso, muestra la lista de selección.
        context.go('/casinos');
      }
    }
  }

  Future<Position> _determinePosition() async {
    LocationPermission permission;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Casino? _findNearestCasino(Position position) {
    Casino? nearestCasino;
    double? minDistance;

    for (final casino in casinos) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        casino.latitude,
        casino.longitude,
      );
      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
        nearestCasino = casino;
      }
    }
    return nearestCasino;
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

