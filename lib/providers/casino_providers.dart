import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final user = ref.watch(userProvider);
  if (user.favoriteCasinoId != null) {
    return user.favoriteCasinoId;
  }

  final casinos = await ref.watch(casinosProvider.future);
  if (casinos.isEmpty) {
    return null;
  }

  // 3. Fallback: siempre Dreams Coyhaique ('4')
  return '4';
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

// --- PROVIDERS DE ESTADO DE LA UI ---

final activeCasinoIdProvider = StateProvider<String?>((ref) => null);
