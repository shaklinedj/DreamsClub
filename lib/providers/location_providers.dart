import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

/// Finds the nearest casino to the user's current location
final nearestCasinoProvider = FutureProvider.autoDispose.family<Casino?, List<Casino>>((ref, casinos) async {
  if (casinos.isEmpty) return null;

  try {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentLocation();

    Casino? nearestCasino;
    double minDistance = double.infinity;

    for (final casino in casinos) {
      final distance = locationService.calculateDistance(
        lat1: position.latitude,
        lon1: position.longitude,
        lat2: casino.latitud,
        lon2: casino.longitud,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestCasino = casino;
      }
    }

    return nearestCasino;
  } catch (e) {
    return null;
  }
});

/// Calculate distance from current location to a specific casino
final distanceToCasinoProvider = FutureProvider.autoDispose.family<double?, Casino>((ref, casino) async {
  try {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService.getCurrentLocation();

    return locationService.calculateDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: casino.latitud,
      lon2: casino.longitud,
    );
  } catch (e) {
    return null;
  }
});
