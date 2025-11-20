import 'package:casinoloyalty_flutter/models/offer_model.dart';
import 'package:casinoloyalty_flutter/services/offer_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final offerServiceProvider = Provider((ref) => OfferService());

final offersProvider = FutureProvider.family<List<Offer>, int>((ref, casinoId) async {
  final offerService = ref.watch(offerServiceProvider);
  return offerService.getOffersByCasinoId(casinoId);
});
