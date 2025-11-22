import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final isInsideCasinoProvider = StreamProvider<bool>((ref) async* {
  final locationService = LocationService();
  final casinoService = CasinoService();

  // Default to false initially
  yield false;

  try {
    final hasPermission = await locationService.hasLocationPermission();
    if (!hasPermission) return;

    final casinos = await casinoService.getAllCasinos();

    // Get current position stream
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // Update every 50 meters
      ),
    );

    await for (final position in stream) {
      bool inside = false;
      for (var casino in casinos) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          casino.latitud,
          casino.longitud,
        );
        // 500 meters radius for "inside" detection
        if (distance <= 500) {
          inside = true;
          break;
        }
      }
      yield inside;
    }
  } catch (e) {
    // If error (e.g. location disabled), assume not inside
    yield false;
  }
});
