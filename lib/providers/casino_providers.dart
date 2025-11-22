import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/user_prefs.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// --- PROVIDERS DE SERVICIOS ---

final casinoServiceProvider = Provider((ref) => CasinoService());

// --- PROVIDERS DE DATOS ---

final casinosProvider = FutureProvider<List<Casino>>((ref) {
  return ref.watch(casinoServiceProvider).getAllCasinos();
});

final selectedCasinoIdProvider = FutureProvider<int?>((ref) async {
  // 1. Si ya hay un casino activo en el estado (seleccionado manualmente), úsalo.
  final activeId = ref.read(activeCasinoIdProvider);
  if (activeId != null) return activeId;

  final casinos = await ref.watch(casinosProvider.future);
  if (casinos.isEmpty) {
    return null;
  }

  // 2. Si hay un favorito guardado, úsalo.
  final favoriteCasinoId = await UserPreferences.getFavoriteCasino();
  if (favoriteCasinoId != null) {
    final match = casinos.where((casino) => casino.id == favoriteCasinoId);
    if (match.isNotEmpty) {
      ref.read(activeCasinoIdProvider.notifier).state = favoriteCasinoId;
      return favoriteCasinoId;
    }
  }

  // 3. Solo si no hay favorito ni selección manual, intenta usar GPS (una sola vez).
  // Esto evita que se recalcule constantemente en la home.
  Position? currentPosition;
  try {
    // Usamos getLastKnownPosition para ser más rápidos y menos intrusivos si es posible
    currentPosition = await Geolocator.getLastKnownPosition();
    currentPosition ??=
        await ref.read(locationServiceProvider).getCurrentLocation();
  } catch (_) {
    currentPosition = null;
  }

  final fallbackId = currentPosition != null
      ? _findClosestCasinoId(casinos, currentPosition)
      : casinos.first.id;

  ref.read(activeCasinoIdProvider.notifier).state = fallbackId;
  return fallbackId;
});

final selectedCasinoProvider = FutureProvider<Casino?>((ref) async {
  final casinos = await ref.watch(casinosProvider.future);
  final selectedId = await ref.watch(selectedCasinoIdProvider.future);
  if (selectedId == null) return null;
  try {
    return casinos.firstWhere((casino) => casino.id == selectedId);
  } catch (_) {
    return null;
  }
});

int _findClosestCasinoId(List<Casino> casinos, Position position) {
  var closestId = casinos.first.id;
  var minDistance = double.infinity;

  for (final casino in casinos) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      casino.latitud,
      casino.longitud,
    );
    if (distance < minDistance) {
      minDistance = distance;
      closestId = casino.id;
    }
  }
  return closestId;
}

// --- PROVIDERS DE ESTADO DE LA UI ---

final activeCasinoIdProvider = StateProvider<int?>((ref) => null);
