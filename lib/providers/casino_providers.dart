import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/event_service.dart';
import 'package:casinoloyalty_flutter/services/favorite_casino_service.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/promotion_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/casino_model.dart';

// --- PROVIDERS DE SERVICIOS ---

// Servicio de geolocalización
final locationServiceProvider = Provider((ref) => LocationService());

// Servicio que maneja los datos de los casinos
final casinoServiceProvider = Provider((ref) => CasinoService());

// Servicio que maneja los datos de eventos
final eventServiceProvider = Provider((ref) => EventService());

// Servicio que maneja los datos de promociones
final promotionServiceProvider = Provider((ref) => PromotionService());

// Servicio para la gestión del casino favorito del usuario
final favoriteCasinoServiceProvider = Provider((ref) => FavoriteCasinoService());


// --- PROVIDERS DE DATOS (lectura de datos desde los servicios) ---

/// Provider que obtiene la lista completa de todos los casinos.
final casinosProvider = FutureProvider<List<Casino>>((ref) {
  return ref.watch(casinoServiceProvider).getAllCasinos();
});

/// Provider que obtiene la lista de promociones para un ID de casino específico.
final promotionsProvider = FutureProvider.family<List<Promotion>, int>((ref, casinoId) {
  return ref.watch(promotionServiceProvider).getPromotionsForCasino(casinoId);
});

/// Provider que obtiene la lista de eventos para un ID de casino específico.
final eventsProvider = FutureProvider.family<List<Event>, int>((ref, casinoId) {
  return ref.watch(eventServiceProvider).getEventsForCasino(casinoId);
});


// --- PROVIDERS DE ESTADO DE LA UI ---

/// Este provider contiene el ID del casino que está activo en la UI.
/// Puede ser el más cercano (por GPS) o el favorito (seleccionado por el usuario).
final activeCasinoIdProvider = StateProvider<int?>((ref) => null);
