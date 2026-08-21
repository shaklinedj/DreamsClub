import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationCheckResult {
  final bool isNear;
  final double? distanceKm;
  final bool serviceDisabled;
  final bool permissionDenied;

  LocationCheckResult({
    required this.isNear,
    this.distanceKm,
    this.serviceDisabled = false,
    this.permissionDenied = false,
  });
}

class CoyhaiqueLocationService {
  static const double dreamsCoyhaiqueLat = -45.57081;
  static const double dreamsCoyhaiqueLng = -72.07419;
  static const double maxDistanceMeters = 1500; // 1.5 km radio de cobertura en Coyhaique

  /// Realiza la verificación completa de ubicación retornando el estado detallado de GPS y permisos
  static Future<LocationCheckResult> checkCoyhaiqueLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationCheckResult(isNear: false, serviceDisabled: true);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationCheckResult(isNear: false, permissionDenied: true);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationCheckResult(isNear: false, permissionDenied: true);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 8),
      );

      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        dreamsCoyhaiqueLat,
        dreamsCoyhaiqueLng,
      );

      final distanceKm = distanceMeters / 1000.0;
      final isNear = distanceMeters <= maxDistanceMeters;

      return LocationCheckResult(
        isNear: isNear,
        distanceKm: distanceKm,
      );
    } catch (e) {
      debugPrint('Error obteniendo ubicación para Coyhaique: $e');
      return LocationCheckResult(isNear: false);
    }
  }

  /// Solicita permisos de ubicación y obtiene la distancia actual a Dreams Coyhaique en KM
  static Future<double?> getDistanceToCoyhaiqueKm() async {
    final result = await checkCoyhaiqueLocation();
    return result.distanceKm;
  }

  /// Verifica si el usuario se encuentra dentro del rango de Dreams Coyhaique
  static Future<bool> isNearDreamsCoyhaique() async {
    final result = await checkCoyhaiqueLocation();
    return result.isNear;
  }
}

