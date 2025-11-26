import 'dart:async';

import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
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
  final locationService = ref.watch(locationServiceProvider);
  final casinosAsync = ref.watch(casinosProvider);
  // If casinos are not yet loaded, use an empty list
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

  // 0.5 km = 500 meters threshold for "near"
  static const double nearThresholdKm = 0.5;

  LocationNotifier(this._locationService, this._casinos)
      : super(const LocationState()) {
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      await _updateLocationState(position);

      // Periodic location checks every 5 minutes
      _timer = Timer.periodic(const Duration(minutes: 5), (_) async {
        final newPos = await _locationService.getCurrentLocation();
        await _updateLocationState(newPos);
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo obtener la ubicación: $e',
      );
    }
  }

  // Main logic: check distance only to the user's favourite casino
  Future<void> _updateLocationState(Position position) async {
    final favoriteId = await UserProfileService().loadFavoriteCasinoId();
    if (favoriteId == null) {
      // No favourite set – treat as not near any casino
      state = state.copyWith(
        currentPosition: position,
        isNearAnyCasino: false,
        nearestCasino: null,
        distanceToNearestCasinoKm: double.infinity,
        isLoading: false,
        error: null,
      );
      return;
    }

    // Find the favourite casino in the loaded list safely
    Casino? favoriteCasino;
    for (final c in _casinos) {
      if (c.id == favoriteId) {
        favoriteCasino = c;
        break;
      }
    }
    if (favoriteCasino == null) {
      // Favourite not in the list – fallback to generic nearest‑casino logic
      _updateLocationStateAllCasinos(position);
      return;
    }

    final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          favoriteCasino.latitud,
          favoriteCasino.longitud,
        ) /
        1000; // km

    state = state.copyWith(
      currentPosition: position,
      isNearAnyCasino: distance <= nearThresholdKm,
      nearestCasino: favoriteCasino,
      distanceToNearestCasinoKm: distance,
      isLoading: false,
      error: null,
    );
  }

  // Helper: original behaviour – find the nearest casino among all
  void _updateLocationStateAllCasinos(Position position) {
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
          1000;
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
