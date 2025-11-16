import 'package:casinoloyalty_flutter/models/hotel_model.dart';
import 'package:casinoloyalty_flutter/services/hotel_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hotelServiceProvider = Provider<HotelService>((ref) {
  return HotelService();
});

final hotelProvider = FutureProvider.family<Hotel?, int>((ref, casinoId) {
  return ref.watch(hotelServiceProvider).getHotelByCasinoId(casinoId);
});
