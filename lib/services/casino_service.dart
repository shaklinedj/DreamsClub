
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/models/hotel_model.dart';
import 'package:casinoloyalty_flutter/models/restaurante_model.dart';
import 'package:casinoloyalty_flutter/models/event_model.dart'; // Import Event model
import 'package:geolocator/geolocator.dart';

class CasinoService {
  final List<Casino> _mockCasinos = [
    Casino(
      id: 1,
      nombre: 'Dreams Iquique',
      ciudad: 'Iquique',
      direccion: 'Av. Arturo Prat 2755, Iquique',
      latitud: -20.2464,
      longitud: -70.1437,
      imageUrl: 'assets/images/iqq.jpg',
      description: 'A pasos de playa Cavancha, diversión frente al mar.',
      features: ['Playa Cavancha', 'Shows en Vivo', 'Gastronomía'],
      rating: 4.6,
      hotel: Hotel(
        id: 1,
        casinoId: 1,
        nombre: 'Hotel Dreams Iquique',
        imageUrl: 'https://images.unsplash.com/photo-1501117716987-c8e1ecb21014?auto=format&fit=crop&w=1200&q=80',
      ),
      restaurantes: [
        Restaurante(
          id: 1,
          casinoId: 1,
          nombre: 'La Pampa',
          imageUrl: 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=1200&q=80',
          type: 'Parrillada',
          description: 'Las mejores carnes a la parrilla en un ambiente exclusivo.',
          rating: 4.8,
          priceRange: '\$\$\$',
        ),
        Restaurante(
          id: 2,
          casinoId: 1,
          nombre: 'Doña Inés',
          imageUrl: 'https://images.unsplash.com/photo-1481931715705-36f5f79f1ff4?auto=format&fit=crop&w=1200&q=80',
          type: 'Buffet',
          description: 'Variedad de sabores nacionales e internacionales.',
          rating: 4.5,
          priceRange: '\$\$',
        ),
      ],
    ),
    Casino(
      id: 2,
      nombre: 'Dreams Temuco',
      ciudad: 'Temuco',
      direccion: 'Av. Alemania 0945, Temuco',
      latitud: -38.7359,
      longitud: -72.5904,
      imageUrl: 'assets/images/temuco.jpg',
      description: 'En el corazón de la Araucanía, lujo y cultura.',
      features: ['Spa Hydra', 'Centro de Eventos', 'Hotel Dreams'],
      rating: 4.7,
      hotel: Hotel(
        id: 2,
        casinoId: 2,
        nombre: 'Hotel Dreams Temuco',
        imageUrl: 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?auto=format&fit=crop&w=1200&q=80',
      ),
      restaurantes: [
        Restaurante(
          id: 3,
          casinoId: 2,
          nombre: 'In',
          imageUrl: 'https://images.unsplash.com/photo-1473093226795-af9932fe5856?auto=format&fit=crop&w=1200&q=80',
          type: 'Fusión',
          description: 'Cocina de autor con ingredientes locales.',
          rating: 4.6,
          priceRange: '\$\$\$',
        ),
        Restaurante(
          id: 4,
          casinoId: 2,
          nombre: 'Pichanga',
          imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
          type: 'Bar & Grill',
          description: 'El mejor lugar para compartir con amigos.',
          rating: 4.4,
          priceRange: '\$\$',
        ),
      ],
    ),
    Casino(
      id: 3,
      nombre: 'Dreams Valdivia',
      ciudad: 'Valdivia',
      direccion: 'Carampangue 190, Valdivia',
      latitud: -39.8142,
      longitud: -73.2459,
      imageUrl: 'assets/images/valdivia.jpg',
      description: 'Ubicación privilegiada con vista al Río Calle-Calle.',
      features: ['Sky Bar', 'Vista al Río', 'Museo'],
      rating: 4.8,
      hotel: Hotel(
        id: 3,
        casinoId: 3,
        nombre: 'Hotel Dreams Valdivia',
        imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=1200&q=80',
      ),
      restaurantes: [
        Restaurante(
          id: 5,
          casinoId: 3,
          nombre: 'Doña Inés',
          imageUrl: 'https://images.unsplash.com/photo-1533777419517-3e4017e2e15c?auto=format&fit=crop&w=1200&q=80',
          type: 'Buffet',
          description: 'La mejor vista al río mientras disfrutas de tu comida.',
          rating: 4.7,
          priceRange: '\$\$',
        ),
        Restaurante(
          id: 6,
          casinoId: 3,
          nombre: 'Sky Bar',
          imageUrl: 'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=1200&q=80',
          type: 'Bar',
          description: 'Cócteles exclusivos y música en vivo.',
          rating: 4.9,
          priceRange: '\$\$\$',
        ),
      ],
    ),
    Casino(
      id: 4,
      nombre: 'Dreams Punta Arenas',
      ciudad: 'Punta Arenas',
      direccion: 'O\'Higgins 1235, Punta Arenas',
      latitud: -53.1638,
      longitud: -70.9171,
      imageUrl: 'assets/images/pta-a.jpg',
      description: 'Entretenimiento en la ciudad más austral del mundo.',
      features: ['Estrecho de Magallanes', 'Sky Bar', 'Zona Franca'],
      rating: 4.6,
      hotel: Hotel(
        id: 4,
        casinoId: 4,
        nombre: 'Hotel Dreams Punta Arenas',
        imageUrl: 'https://images.unsplash.com/photo-1572715376701-98568319fd0a?auto=format&fit=crop&w=1200&q=80',
      ),
      restaurantes: [
        Restaurante(
          id: 7,
          casinoId: 4,
          nombre: 'Doña Inés',
          imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
          type: 'Buffet',
          description: 'Sabores patagónicos en un ambiente acogedor.',
          rating: 4.5,
          priceRange: '\$\$',
        ),
        Restaurante(
          id: 8,
          casinoId: 4,
          nombre: 'Sky Bar',
          imageUrl: 'https://images.unsplash.com/photo-1457460866886-40ef8d4b42a0?auto=format&fit=crop&w=1200&q=80',
          type: 'Bar',
          description: 'La mejor vista del estrecho de Magallanes.',
          rating: 4.8,
          priceRange: '\$\$\$',
        ),
      ],
    ),
    Casino(
      id: 5,
      nombre: 'Monticello',
      ciudad: 'Mostazal',
      direccion: 'Panamericana Sur, Km. 57, Mostazal',
      latitud: -34.0733,
      longitud: -70.7303,
      imageUrl: 'assets/images/fachada-monticello.jpg',
      description: 'El centro de entretención más grande de Latinoamérica.',
      features: ['Arena Monticello', 'Hotel 5 Estrellas', 'Paseo Murano'],
      rating: 4.9,
      hotel: Hotel(
        id: 5,
        casinoId: 5,
        nombre: 'Hotel Monticello',
        imageUrl: 'https://images.unsplash.com/photo-1542318428-29f26af1ff86?auto=format&fit=crop&w=1200&q=80',
      ),
      restaurantes: [
        Restaurante(
          id: 9,
          casinoId: 5,
          nombre: 'El Pescador',
          imageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
          type: 'Mariscos',
          description: 'Los productos más frescos del mar a tu mesa.',
          rating: 4.8,
          priceRange: '\$\$\$\$',
        ),
        Restaurante(
          id: 10,
          casinoId: 5,
          nombre: 'El Rincón del Chef',
          imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?auto=format&fit=crop&w=1200&q=80',
          type: 'Gourmet',
          description: 'Experiencia culinaria de alto nivel.',
          rating: 4.9,
          priceRange: '\$\$\$\$',
        ),
        Restaurante(
          id: 11,
          casinoId: 5,
          nombre: 'La Pica de la Esquina',
          imageUrl: 'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1200&q=80',
          type: 'Chilena',
          description: 'Comida típica chilena con un toque moderno.',
          rating: 4.5,
          priceRange: '\$\$',
        ),
      ],
    ),
    Casino(
      id: 6,
      nombre: 'Dreams Puerto Varas',
      ciudad: 'Puerto Varas',
      direccion: 'Del Salvador 21, Puerto Varas',
      latitud: -41.3204,
      longitud: -72.9839,
      imageUrl: 'assets/images/pto-v.jpg',
      description: 'A orillas del Lago Llanquihue, con vista a los volcanes.',
      features: ['Lago Llanquihue', 'Entorno Natural', 'Turismo'],
      rating: 4.8,
      hotel: Hotel(
        id: 6,
        casinoId: 6,
        nombre: 'Hotel Dreams Puerto Varas',
        imageUrl: 'https://images.unsplash.com/photo-1571896349842-33c89424de2d?auto=format&fit=crop&w=1200&q=80',
      ),
      restaurantes: [
        Restaurante(
          id: 12,
          casinoId: 6,
          nombre: 'Doña Inés',
          imageUrl: 'https://images.unsplash.com/photo-1528605248644-14dd04022da1?auto=format&fit=crop&w=1200&q=80',
          type: 'Buffet',
          description: 'Disfruta de la gastronomía sureña.',
          rating: 4.6,
          priceRange: '\$\$',
        ),
        Restaurante(
          id: 13,
          casinoId: 6,
          nombre: 'Sky Bar',
          imageUrl: 'https://images.unsplash.com/photo-1552566626-10d0c6462d0d?auto=format&fit=crop&w=1200&q=80',
          type: 'Bar',
          description: 'Vista panorámica al lago y volcanes.',
          rating: 4.9,
          priceRange: '\$\$\$',
        ),
      ],
    ),
    Casino(
      id: 7,
      nombre: 'Dreams Coyhaique',
      ciudad: 'Coyhaique',
      direccion: 'Magallanes 131, Coyhaique',
      latitud: -45.5715,
      longitud: -72.0694,
      imageUrl: 'assets/images/coy.jpg',
      description: 'Diversión en la patagonia chilena.',
      features: ['Patagonia', 'Naturaleza', 'Bar Lucky 7'],
      rating: 4.5,
      hotel: Hotel(
        id: 7,
        casinoId: 7,
        nombre: 'Hotel Dreams Coyhaique',
        imageUrl: 'https://images.unsplash.com/photo-1559813817-127ef2fc4dd1?auto=format&fit=crop&w=1200&q=80',
      ),
      restaurantes: [
        Restaurante(
          id: 14,
          casinoId: 7,
          nombre: 'Donde el Chef',
          imageUrl: 'https://images.unsplash.com/photo-1481833761820-0509d3217039?auto=format&fit=crop&w=1200&q=80',
          type: 'Internacional',
          description: 'Platos elaborados con productos de la zona.',
          rating: 4.6,
          priceRange: '\$\$\$',
        ),
        Restaurante(
          id: 15,
          casinoId: 7,
          nombre: 'El Fogón',
          imageUrl: 'https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=1200&q=80',
          type: 'Carnes',
          description: 'El mejor asado patagónico.',
          rating: 4.7,
          priceRange: '\$\$',
        ),
      ],
    ),
  ];

  final List<Event> _mockEvents = [
    Event(
      id: 1,
      casinoId: 1,
      titulo: 'Noche de Jazz',
      descripcion: 'Disfruta de los mejores exponentes del Jazz nacional.',
      fecha: DateTime.now().add(const Duration(days: 2)),
      imageUrl: 'https://images.unsplash.com/photo-1511192336575-5a79af67a629?auto=format&fit=crop&w=1200&q=80',
      type: 'Música',
      location: 'Bar Lucky 7',
      price: 'Gratis',
    ),
    Event(
      id: 2,
      casinoId: 5,
      titulo: 'Sorteo BMW',
      descripcion: 'Gran sorteo de un BMW 0KM. ¡No te lo pierdas!',
      fecha: DateTime.now().add(const Duration(days: 5)),
      imageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=1200&q=80',
      type: 'Sorteo',
      location: 'Salón Principal',
      price: 'Socios',
    ),
    Event(
      id: 3,
      casinoId: 2,
      titulo: 'Stand Up Comedy',
      descripcion: 'Risas aseguradas con los mejores comediantes.',
      fecha: DateTime.now().add(const Duration(days: 1)),
      imageUrl: 'https://images.unsplash.com/photo-1585699324551-f6c309eedeca?auto=format&fit=crop&w=1200&q=80',
      type: 'Show',
      location: 'Teatro Dreams',
      price: '\$10.000',
    ),
    Event(
      id: 4,
      casinoId: 3,
      titulo: 'Fiesta 80s',
      descripcion: 'Ven a bailar los mejores hits de los 80.',
      fecha: DateTime.now().add(const Duration(days: 3)),
      imageUrl: 'https://images.unsplash.com/photo-1545128485-c400e7702796?auto=format&fit=crop&w=1200&q=80',
      type: 'Fiesta',
      location: 'Discotheque',
      price: '\$5.000',
    ),
  ];

  Future<List<Casino>> getAllCasinos() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockCasinos;
  }

  Future<Casino> getNearestCasino(double latitude, double longitude) async {
    final casinos = await getAllCasinos();
    if (casinos.isEmpty) {
      throw Exception('No casinos available to determine the nearest one.');
    }

    Casino nearestCasino = casinos.first;
    double minDistance = double.infinity;

    for (var casino in casinos) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        casino.latitud,
        casino.longitud,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestCasino = casino;
      }
    }
    return nearestCasino;
  }

  Future<Casino> getCasinoById(int id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockCasinos.firstWhere(
      (casino) => casino.id == id,
      orElse: () => throw Exception('Casino with id $id not found'),
    );
  }

  Future<List<Event>> getEventsByCasino(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockEvents.where((e) => e.casinoId == casinoId).toList();
  }
}
