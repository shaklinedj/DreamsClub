
import 'package:casinoloyalty_flutter/models/promotion_model.dart';

class PromotionService {
  final List<Promotion> _mockPromotions = [
    // Promotions for Casino 1 (Iquique)
    Promotion(
      id: 1,
      casinoId: 1,
      titulo: 'Noches de Sabor y Suerte',
      descripcion: 'Disfruta de una experiencia culinaria única en nuestro restaurante "La Pampa" y recibe un cupón de \$10.000 para jugar en nuestras máquinas. Válido de lunes a jueves.',
      imageUrl: 'https://picsum.photos/seed/promo1/800/600',
    ),
    Promotion(
      id: 2,
      casinoId: 1,
      titulo: 'Sorteo Auto 0km',
      descripcion: 'Por cada \$20.000 que juegues en nuestras mesas, acumulas un cupón para el gran sorteo de un auto 0km a fin de mes. ¡No te quedes fuera!',
      imageUrl: 'https://picsum.photos/seed/promo2/800/600',
    ),

    // Promotions for Casino 2 (Temuco)
    Promotion(
      id: 3,
      casinoId: 2,
      titulo: 'Miércoles de Doble Puntaje',
      descripcion: 'Todos los miércoles, los socios de nuestro club de lealtad duplican los puntos acumulados en todas las máquinas de azar. ¡Más puntos, más premios!',
      imageUrl: 'https://picsum.photos/seed/promo3/800/600',
    ),

    // Promotions for Casino 3 (Valdivia)
    Promotion(
      id: 4,
      casinoId: 3,
      titulo: 'Happy Hour en Sky Bar',
      descripcion: 'Disfruta de un 2x1 en todos nuestros cócteles de autor en el Sky Bar, con la mejor vista de la ciudad. De 18:00 a 20:00 hrs.',
      imageUrl: 'https://picsum.photos/seed/promo4/800/600',
    ),

    // Promotions for Casino 4 (Punta Arenas)
    Promotion(
      id: 5,
      casinoId: 4,
      titulo: 'Fin de Semana de Poker',
      descripcion: 'Inscríbete en nuestro torneo de Texas Hold\'em y compite por un pozo garantizado de \$5.000.000. ¡Demuestra que eres el mejor!',
      imageUrl: 'https://picsum.photos/seed/promo5/800/600',
    ),

    // Promotions for Casino 5 (Monticello)
    Promotion(
      id: 6,
      casinoId: 5,
      titulo: 'Buffet Internacional con Descuento',
      descripcion: 'Presenta tu tarjeta de socio y obtén un 30% de descuento en nuestro exquisito buffet internacional. Sabores del mundo en un solo lugar.',
      imageUrl: 'https://picsum.photos/seed/promo6/800/600',
    ),
     Promotion(
      id: 10,
      casinoId: 5,
      titulo: 'Sorteo Millonario',
      descripcion: 'Cada visita a Monticello te da una oportunidad de ganar. Participa en nuestros sorteos diarios y podrías llevarte premios millonarios en efectivo.',
      imageUrl: 'https://picsum.photos/seed/promo10/800/600',
    ),


    // Promotions for Casino 6 (Puerto Varas)
    Promotion(
      id: 7,
      casinoId: 6,
      titulo: 'Escapada Romántica',
      descripcion: 'Paquete especial para dos personas: incluye una noche de alojamiento en nuestro hotel, cena en restaurante "Doña Inés" y créditos para el casino.',
      imageUrl: 'https://picsum.photos/seed/promo7/800/600',
    ),

    // Promotions for Casino 7 (Coyhaique)
    Promotion(
      id: 8,
      casinoId: 7,
      titulo: 'Sabores de la Patagonia',
      descripcion: 'Menú de degustación en "Donde el Chef", con ingredientes locales y una selección de vinos de la región. Una experiencia inolvidable.',
      imageUrl: 'https://picsum.photos/seed/promo8/800/600',
    ),
     Promotion(
      id: 9,
      casinoId: 7,
      titulo: 'Jueves de Chicas',
      descripcion: 'Las mujeres tienen beneficios especiales los jueves. Tragos de cortesía, descuentos en cenas y sorteos exclusivos para ellas toda la noche.',
      imageUrl: 'https://picsum.photos/seed/promo9/800/600',
    ),
    
    // New Promotions
    Promotion(
      id: 11,
      casinoId: 1,
      titulo: 'Domingo Familiar',
      descripcion: 'Ven con tu familia y disfruta de un 20% de descuento en el buffet de almuerzo. Además, juegos y actividades para los más pequeños.',
      imageUrl: 'https://picsum.photos/seed/promo11/800/600',
    ),
    Promotion(
      id: 12,
      casinoId: 5,
      titulo: 'Noche de Casino Royale',
      descripcion: 'Vístete de gala y vive una noche al estilo James Bond. Cócteles temáticos, música en vivo y premios especiales en las mesas de juego.',
      imageUrl: 'https://picsum.photos/seed/promo12/800/600',
    ),
    Promotion(
      id: 13,
      casinoId: 3,
      titulo: 'Descuento en Spa Hydra',
      descripcion: 'Relájate con un 15% de descuento en todos nuestros masajes y tratamientos faciales. Reserva tu hora y renueva tus energías.',
      imageUrl: 'https://picsum.photos/seed/promo13/800/600',
    ),
  ];

  Future<List<Promotion>> getPromotionsByCasinoId(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockPromotions.where((promo) => promo.casinoId == casinoId).toList();
  }

  Future<Promotion> getPromotionById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockPromotions.firstWhere((promo) => promo.id == id);
  }
}
