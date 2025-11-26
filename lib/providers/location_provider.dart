import 'dart:async';
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final casinosAsync = ref.watch(casinosProvider);

  // Default to empty list if casinos are not yet loaded
  final casinos = casinosAsync.value ?? [];

  return LocationNotifier(locationService, casinos);
});

class LocationState {
  final Position? currentPosition;
  final bool isNearAnyCasino;
  final Casino? nearestCasino;
  final double distanceToNearestCasinoKm;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.currentPosition,
    this.isNearAnyCasino = false,
    this.nearestCasino,
    this.distanceToNearestCasinoKm = double.infinity,
    this.isLoading = true,
    this.error,
  });

  LocationState copyWith({
    Position? currentPosition,
    bool? isNearAnyCasino,
    Casino? nearestCasino,
    double? distanceToNearestCasinoKm,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isNearAnyCasino: isNearAnyCasino ?? this.isNearAnyCasino,
      nearestCasino: nearestCasino ?? this.nearestCasino,
      distanceToNearestCasinoKm:
          distanceToNearestCasinoKm ?? this.distanceToNearestCasinoKm,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;
  final List<Casino> _casinos;
  Timer? _timer;

  // Threshold in KM to consider "near" a casino
  static const double nearThresholdKm = 100.0;

  LocationNotifier(this._locationService, this._casinos)
      : super(const LocationState()) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      _updateLocationState(position);

      // Start periodic updates
      _timer = Timer.periodic(const Duration(minutes: 5), (_) async {
        final newPosition = await _locationService.getCurrentLocation();
        _updateLocationState(newPosition);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo obtener la ubicación: $e',
      );
    }
  }

  void _updateLocationState(Position position) {
    if (_casinos.isEmpty) {
      state = state.copyWith(
        currentPosition: position,
        isLoading: false,
      );
      return;
    }

    Casino? nearest;
    double minDistance = double.infinity;

    for (final casino in _casinos) {
      final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            casino.latitud,
            casino.longitud,
          ) /
          1000; // Convert to KM

      if (distance < minDistance) {
        minDistance = distance;
        nearest = casino;
      }
    }

    state = state.copyWith(
      currentPosition: position,
      isNearAnyCasino: minDistance <= nearThresholdKm,
      nearestCasino: nearest,
      distanceToNearestCasinoKm: minDistance,
      isLoading: false,
      error: null,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
