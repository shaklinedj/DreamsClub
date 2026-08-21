import 'dart:async';
import 'package:casinoloyalty_flutter/models/casino_model.dart';

class LocationService {
  static const double casinoProximityMeters = 500.0;

  Function(String casinoId)? onCasinoVisit;

  /// Check if location permission has been granted - always returns true to allow unrestricted access
  Future<bool> hasLocationPermission() async {
    return true;
  }

  /// Request location permission - safe no-op
  Future<bool> requestLocationPermission() async {
    return true;
  }

  /// Request always permission - safe no-op
  Future<bool> requestAlwaysPermission() async {
    return true;
  }

  /// Inicia el monitoreo (no-op sin GPS)
  Future<void> startLocationMonitoring({
    required List<Casino> casinos,
    required Function(String casinoId) onCasinoVisit,
  }) async {
    this.onCasinoVisit = onCasinoVisit;
  }

  /// Detiene el monitoreo
  void stopLocationMonitoring() {}

  /// Verifica si el usuario está actualmente en un casino (siempre activo para juegos)
  Future<String?> checkIfInCasino(List<Casino> casinos) async {
    if (casinos.isNotEmpty) {
      return casinos.first.id;
    }
    return null;
  }

  void resetSessionVisits() {}
}

