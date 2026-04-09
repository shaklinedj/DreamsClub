import 'dart:async';
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';

import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// Provider for the location service
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// Provider for location state, depends on the list of casinos
final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final casinosAsync = ref.watch(casinosProvider);
  final notifier = LocationNotifier();

  casinosAsync.whenData((casinos) {
    notifier.updateCasinos(casinos);
  });

  return notifier;
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
  // 0.5 km = 500 meters threshold for "near"
  static const double nearThresholdKm = 0.5;

  final LocationService _locationService = LocationService();
  final List<Casino> _casinos = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  LocationNotifier() : super(const LocationState()) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        state = state.copyWith(
          isLoading: false,
          error: 'Permisos de ubicación no otorgados',
        );
        return;
      }

      // Try last known position for immediate feedback
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _updateLocationState(lastKnown);
        }
      } catch (_) {}

      // Start stream
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100m
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        _updateLocationState(position);
      }, onError: (e) {
        if (mounted) {
          state = state.copyWith(isLoading: false, error: e.toString());
        }
      });

      // Force a fresh update with timeout
      try {
        final position = await _locationService
            .getCurrentLocation()
            .timeout(const Duration(seconds: 5));
        _updateLocationState(position);
      } catch (e) {
        // If timed out and no position yet
        if (state.currentPosition == null && mounted) {
          state = state.copyWith(
              isLoading: false, error: "No se pudo obtener ubicación precisa.");
        }
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  void updateCasinos(List<Casino> casinos) {
    if (_casinos.length == casinos.length) return; // Simple check
    _casinos.clear();
    _casinos.addAll(casinos);
    if (state.currentPosition != null) {
      _updateLocationState(state.currentPosition!);
    }
  }

  Future<void> _updateLocationState(Position position) async {
    Casino? nearest;
    double minDistance = double.infinity;
    bool isNear = false;

    if (_casinos.isNotEmpty) {
      for (final casino in _casinos) {
        final distance = _locationService.calculateDistance(
          lat1: position.latitude,
          lon1: position.longitude,
          lat2: casino.latitud,
          lon2: casino.longitud,
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearest = casino;
        }
      }

      if (minDistance <= nearThresholdKm) {
        isNear = true;
      }
    }

    if (mounted) {
      state = state.copyWith(
        currentPosition: position,
        isNearAnyCasino: isNear,
        nearestCasino: nearest,
        distanceToNearestCasinoKm: minDistance,
        isLoading: false,
        error: null,
      );
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}

/// Finds the nearest casino to the user's current location
/// If GPS is not available, returns null for manual selection
final nearestCasinoProvider = FutureProvider.autoDispose
    .family<Casino?, List<Casino>>((ref, casinos) async {
  if (casinos.isEmpty) return null;

  try {
    final locationService = ref.read(locationServiceProvider);
    final position = await locationService
        .getCurrentLocation()
        .timeout(const Duration(seconds: 5));

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
