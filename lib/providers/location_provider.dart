import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the location service
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

// Provider for location state, depends on the list of casinos
final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final casinosAsync = ref.watch(casinosProvider);
  final user = ref.watch(userProvider);
  final notifier = LocationNotifier();

  casinosAsync.whenData((casinos) {
    notifier.updateCasinos(casinos, user.favoriteCasinoId);
  });

  return notifier;
});

class LocationState {
  final bool isNearAnyCasino;
  final Casino? nearestCasino;
  final double distanceToNearestCasinoKm;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.isNearAnyCasino = true,
    this.nearestCasino,
    this.distanceToNearestCasinoKm = 0.0,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    bool? isNearAnyCasino,
    Casino? nearestCasino,
    double? distanceToNearestCasinoKm,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
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
  final List<Casino> _casinos = [];

  LocationNotifier() : super(const LocationState(isNearAnyCasino: true, isLoading: false));

  void updateCasinos(List<Casino> casinos, [String? favoriteCasinoId]) {
    _casinos.clear();
    _casinos.addAll(casinos);
    if (_casinos.isNotEmpty && mounted) {
      final favId = favoriteCasinoId ?? '4'; // '4' is Dreams Coyhaique
      final preferredCasino = _casinos.firstWhere(
        (c) => c.id == favId,
        orElse: () => _casinos.firstWhere(
          (c) => c.id == '4',
          orElse: () => _casinos.first,
        ),
      );

      state = state.copyWith(
        isNearAnyCasino: true,
        nearestCasino: preferredCasino,
        distanceToNearestCasinoKm: 0.0,
        isLoading: false,
        error: null,
      );
    }
  }
}

/// Finds the nearest casino
final nearestCasinoProvider = FutureProvider.autoDispose
    .family<Casino?, List<Casino>>((ref, casinos) async {
  if (casinos.isEmpty) return null;
  final user = ref.read(userProvider);
  final favId = user.favoriteCasinoId ?? '4';
  return casinos.firstWhere(
    (c) => c.id == favId,
    orElse: () => casinos.firstWhere(
      (c) => c.id == '4',
      orElse: () => casinos.first,
    ),
  );
});

