import 'package:casinoloyalty_flutter/models/restaurante_model.dart';
import 'package:casinoloyalty_flutter/services/restaurant_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final restaurantServiceProvider = Provider<RestaurantService>((ref) {
  return RestaurantService();
});

final restaurantsProvider = FutureProvider.family<List<Restaurante>, int>((ref, casinoId) {
  return ref.watch(restaurantServiceProvider).getRestaurantsByCasinoId(casinoId);
});
