import 'package:casinoloyalty_flutter/models/promotion_model.dart';

class PromotionService {
  final Map<int, List<Promotion>> _promotions = {
    1: [
      Promotion(
          id: 1,
          casinoId: 1,
          titulo: 'Happy Hour 2x1',
          descripcion: 'Todos los días de 18:00 a 20:00 hrs.',
          imageUrl: 'https://picsum.photos/seed/promo1/400/300'),
      Promotion(
          id: 2,
          casinoId: 1,
          titulo: 'Miércoles de Chicas',
          descripcion: 'Tragos gratis para ellas toda la noche.',
          imageUrl: 'https://picsum.photos/seed/promo2/400/300'),
    ],
    2: [
      Promotion(
          id: 3,
          casinoId: 2,
          titulo: 'Jueves de Amigos',
          descripcion: '20% de descuento en mesas.',
          imageUrl: 'https://picsum.photos/seed/promo3/400/300'),
    ],
    4: [
      Promotion(
          id: 4,
          casinoId: 4,
          titulo: 'Sábado Familiar',
          descripcion: 'Menú infantil a mitad de precio.',
          imageUrl: 'https://picsum.photos/seed/promo4/400/300'),
    ],
  };

  Future<List<Promotion>> getPromotionsByCasinoId(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _promotions[casinoId] ?? [];
  }
}
