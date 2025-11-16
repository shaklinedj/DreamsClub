import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/favorite_casino_service.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/casino_model.dart';

// --- PROVIDERS DE SERVICIOS ---

final locationServiceProvider = Provider((ref) => LocationService());
final casinoServiceProvider = Provider((ref) => CasinoService());
final favoriteCasinoServiceProvider =
    Provider((ref) => FavoriteCasinoService());


// --- PROVIDERS DE DATOS ---

final casinosProvider = FutureProvider<List<Casino>>((ref) {
  return ref.watch(casinoServiceProvider).getAllCasinos();
});


// --- PROVIDERS DE ESTADO DE LA UI ---

final activeCasinoIdProvider = StateProvider<int?>((ref) => null);
