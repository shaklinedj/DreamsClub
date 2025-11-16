
import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:casinoloyalty_flutter/services/promotion_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final promotionServiceProvider = Provider((ref) => PromotionService());

final promotionsProvider = FutureProvider.family<List<Promotion>, int>((ref, casinoId) async {
  final promotionService = ref.watch(promotionServiceProvider);
  return promotionService.getPromotionsByCasinoId(casinoId);
});

final promotionDetailsProvider = FutureProvider.family<Promotion, int>((ref, promotionId) async {
  final promotionService = ref.watch(promotionServiceProvider);
  return promotionService.getPromotionById(promotionId);
});
