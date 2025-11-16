import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class DecisionScreen extends ConsumerStatefulWidget {
  const DecisionScreen({super.key});

  @override
  ConsumerState<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends ConsumerState<DecisionScreen> {
  @override
  void initState() {
    super.initState();
    _decideInitialRoute();
  }

  Future<void> _decideInitialRoute() async {
    try {
      final position = await ref.read(locationServiceProvider).getCurrentLocation();
      final allCasinos = await ref.read(casinosProvider.future);
      
      Casino? nearestCasino;
      double? minDistance;

      for (var casino in allCasinos) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          casino.latitud,
          casino.longitud,
        );

        if (minDistance == null || distance < minDistance) {
          minDistance = distance;
          nearestCasino = casino;
        }
      }

      if (mounted && nearestCasino != null) {
        ref.read(activeCasinoIdProvider.notifier).state = nearestCasino.id;
        context.go('/home');
      }

    } catch (e) {
      final favoriteId = await ref.read(favoriteCasinoServiceProvider).getFavoriteCasino();
      if (mounted) {
        if (favoriteId != null) {
          ref.read(activeCasinoIdProvider.notifier).state = favoriteId;
          context.go('/home');
        } else {
          context.go('/select-favorite');
        }
      }
    }
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
            Text('Determinando tu casino más cercano...'),
          ],
        ),
      ),
    );
  }
}
