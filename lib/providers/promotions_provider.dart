import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:casinoloyalty_flutter/services/promotion_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final promotionServiceProvider = Provider<PromotionService>((ref) {
  return PromotionService();
});

final promotionsProvider = FutureProvider.family<List<Promotion>, int>((ref, casinoId) {
  return ref.watch(promotionServiceProvider).getPromotionsByCasinoId(casinoId);
});
