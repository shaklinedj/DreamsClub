import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// --- PROVIDERS DE SERVICIOS ---

final casinoServiceProvider = Provider((ref) => CasinoService());

// --- PROVIDERS DE DATOS ---

final casinosProvider = FutureProvider<List<Casino>>((ref) {
  return ref.watch(casinoServiceProvider).getAllCasinos();
});

final selectedCasinoIdProvider = FutureProvider<String?>((ref) async {
  // 1. Si ya hay un casino activo en el estado (seleccionado manualmente durante la sesión), úsalo.
  final activeId = ref.watch(activeCasinoIdProvider);
  if (activeId != null) return activeId;

  // 2. Si hay un favorito en el perfil del usuario, úsalo.
  // Observamos el userProvider para reaccionar a cambios inmediatos.
  final user = ref.watch(userProvider);
  if (user.favoriteCasinoId != null) {
    return user.favoriteCasinoId;
  }

  final casinos = await ref.watch(casinosProvider.future);
  if (casinos.isEmpty) {
    return null;
  }

  // 3. Fallback: Intentar obtener ubicación GPS para elegir el más cercano si no hay favorito
  try {
    final currentPosition = await Geolocator.getLastKnownPosition() ??
        await ref.read(locationServiceProvider).getCurrentLocation();

    // Si tenemos ubicación, encontrar el más cercano
    final closestId = _findClosestCasinoId(casinos, currentPosition);
    // Nota: No guardamos automáticamente como favorito aquí, solo sugerimos.
    // Tampoco seteamos activeCasinoIdProvider para permitir que el favorito tome precedencia si se configura después.
    return closestId;
  } catch (_) {
    // Si no hay permisos o falla GPS, retornar null para forzar selección manual
    return null;
  }
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

String _findClosestCasinoId(List<Casino> casinos, Position position) {
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

final activeCasinoIdProvider = StateProvider<String?>((ref) => null);
