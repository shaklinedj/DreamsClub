import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/models/hotel_model.dart';
import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:casinoloyalty_flutter/models/restaurant_model.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/event_service.dart';
import 'package:casinoloyalty_flutter/services/favorite_casino_service.dart';
import 'package:casinoloyalty_flutter/services/hotel_service.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/promotion_service.dart';
import 'package:casinoloyalty_flutter/services/restaurant_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/casino_model.dart';

// --- PROVIDERS DE SERVICIOS ---

final locationServiceProvider = Provider((ref) => LocationService());
final casinoServiceProvider = Provider((ref) => CasinoService());
final eventServiceProvider = Provider((ref) => EventService());
final promotionServiceProvider = Provider((ref) => PromotionService());
final favoriteCasinoServiceProvider =
    Provider((ref) => FavoriteCasinoService());
final hotelServiceProvider = Provider((ref) => HotelService());
final restaurantServiceProvider = Provider((ref) => RestaurantService());

// --- PROVIDERS DE DATOS ---

final casinosProvider = FutureProvider<List<Casino>>((ref) {
  return ref.watch(casinoServiceProvider).getAllCasinos();
});

final promotionsProvider =
    FutureProvider.family<List<Promotion>, int>((ref, casinoId) {
  return ref.watch(promotionServiceProvider).getPromotionsForCasino(casinoId);
});

final eventsProvider = FutureProvider.family<List<Event>, int>((ref, casinoId) {
  return ref.watch(eventServiceProvider).getEventsForCasino(casinoId);
});

final hotelsProvider = FutureProvider.family<List<Hotel>, int>((ref, casinoId) {
  return ref.watch(hotelServiceProvider).getHotelsForCasino(casinoId);
});

final restaurantsProvider =
    FutureProvider.family<List<Restaurante>, int>((ref, casinoId) {
  return ref.watch(restaurantServiceProvider).getRestaurantsForCasino(casinoId);
});

// --- PROVIDERS DE ESTADO DE LA UI ---

final activeCasinoIdProvider = StateProvider<int?>((ref) => null);
