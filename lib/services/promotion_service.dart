import 'package:casinoloyalty_flutter/models/promotion_model.dart';

class PromotionService {
  final List<Promotion> _mockPromotions = [
    // Promociones para Dreams Temuco (casinoId: 2)
    Promotion(
      id: 201,
      casinoId: 2,
      titulo: 'Miércoles 2x1 en Tragos',
      descripcion:
          'Todos los miércoles, pide un trago y te regalamos el segundo. Válido en todos nuestros bares.',
    ),
    Promotion(
      id: 202,
      casinoId: 2,
      titulo: 'Sorteo Auto 0km',
      descripcion:
          'Acumula puntos con tus jugadas y participa por un increíble auto 0km. Sorteo a fin de mes.',
    ),

    // Promociones para Dreams Punta Arenas (casinoId: 4)
    Promotion(
      id: 401,
      casinoId: 4,
      titulo: 'Buffet Patagónico con Descuento',
      descripcion:
          'Disfruta de nuestro exquisito buffet con sabores de la Patagonia con un 20% de descuento para socios.',
    ),

    // Promociones para Dreams Iquique (casinoId: 1)
    Promotion(
      id: 101,
      casinoId: 1,
      titulo: 'El Club del Boleto',
      descripcion: 'Junta tus boletos y participa por increíbles premios.',
    ),
    Promotion(
      id: 102,
      casinoId: 1,
      titulo: 'Mesas Millonarias',
      descripcion: 'Gana premios millonarios en nuestras mesas de juego.',
    ),
    Promotion(
      id: 103,
      casinoId: 1,
      titulo: 'Perfect Match',
      descripcion: 'Encuentra tu pareja perfecta y gana premios en dinero.',
    ),

    // Promociones para Dreams Valdivia (casinoId: 3)
    Promotion(
      id: 301,
      casinoId: 3,
      titulo: 'Jueves de Chicas',
      descripcion:
          'Los jueves son de ellas. Disfruta de tragos de cortesía y sorpresas.',
    ),
    Promotion(
      id: 302,
      casinoId: 3,
      titulo: 'Sorteo Vacaciones Soñadas',
      descripcion:
          'Participa por un viaje para dos personas a un destino paradisíaco.',
    ),
  ];

  Future<List<Promotion>> getPromotionsForCasino(int casinoId) async {
    // Simula una llamada a la API
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockPromotions
        .where((promo) => promo.casinoId == casinoId)
        .toList();
  }
}
