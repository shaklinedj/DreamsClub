import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/event_service.dart';
import 'package:casinoloyalty_flutter/services/favorite_casino_service.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/promotion_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final casinoServiceProvider = Provider<CasinoService>((ref) {
  return CasinoService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final favoriteCasinoServiceProvider = Provider<FavoriteCasinoService>((ref) {
  return FavoriteCasinoService();
});

final promotionServiceProvider = Provider<PromotionService>((ref) {
  return PromotionService();
});

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

final casinosProvider = FutureProvider<List<Casino>>((ref) {
  return ref.watch(casinoServiceProvider).getAllCasinos();
});

final nearestCasinoProvider = FutureProvider<Casino>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  final casinoService = ref.watch(casinoServiceProvider);
  final favoriteCasinoService = ref.watch(favoriteCasinoServiceProvider);

  try {
    final position = await locationService.getCurrentLocation();
    return await casinoService.getNearestCasino(position.latitude, position.longitude);
  } catch (e) {
    final favoriteCasinoId = await favoriteCasinoService.getFavoriteCasino();
    if (favoriteCasinoId != null) {
      final casinos = await casinoService.getAllCasinos();
      return casinos.firstWhere((casino) => casino.id == favoriteCasinoId);
    }
    throw Exception('Location permission denied and no favorite casino set.');
  }
});

final promotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final casino = await ref.watch(nearestCasinoProvider.future);
  return ref.watch(promotionServiceProvider).getPromotionsByCasino(casino.id);
});

final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final casino = await ref.watch(nearestCasinoProvider.future);
  return ref.watch(eventServiceProvider).getEventsByCasino(casino.id);
});
