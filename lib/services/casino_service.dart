import 'dart:math' as math;
import 'package:casinoloyalty_flutter/models/casino_model.dart';

class CasinoService {

  // Hardcoded casinos for speed and offline availability
  static const List<Casino> staticCasinos = [
    Casino(
      id: '1',
      nombre: 'Dreams Iquique',
      ciudad: 'Iquique',
      direccion: 'Av. Arturo Prat 2755, Iquique',
      latitud: -20.23528,
      longitud: -70.14722,
      imageUrl: 'assets/images/iqq.jpg',
      description: 'A pasos de Playa Cavancha, entretenimiento de primer nivel, gastronomía y shows en vivo.',
      features: ['Playa Cavancha', 'Gastronomía Regional', 'Shows en Vivo', 'Salas de Juego'],
      rating: 4.6,
      schedules: {'Lunes-Domingo': '24 Horas'},
      websiteUrl: 'https://iquique.dreams.cl/',
      reservationUrl: null,
    ),
    Casino(
      id: '2',
      nombre: 'Dreams Temuco',
      ciudad: 'Temuco',
      direccion: 'Av. Alemania 0945, Temuco',
      latitud: -38.73315,
      longitud: -72.61541,
      imageUrl: 'assets/images/temuco.jpg',
      description: 'El centro de entretenimiento más grande de la Araucanía.',
      features: ['Centro de Convenciones', 'Restaurante In', 'Sky Bar', 'Shows'],
      rating: 4.5,
      schedules: {'Lunes-Domingo': '10:00 - 05:00'},
      websiteUrl: 'https://temuco.dreams.cl/',
      reservationUrl: 'https://reservations.dreams.cl/es/araucania/book/dates-of-stay',
    ),
    Casino(
      id: '3',
      nombre: 'Dreams Valdivia',
      ciudad: 'Valdivia',
      direccion: 'Carampangue 190, Valdivia',
      latitud: -39.8113,
      longitud: -73.24611,
      imageUrl: 'assets/images/valdivia.jpg',
      description: 'A orillas del Río Calle-Calle con arquitectura icónica y gastronomía fluvial.',
      features: ['Vista al Río', 'Sky Bar 360', 'Cervecería Artesanal', 'Hotel'],
      rating: 4.7,
      schedules: {'Lunes-Domingo': '12:00 - 04:00'},
      websiteUrl: 'https://valdivia.dreams.cl/',
      reservationUrl: 'https://reservations.dreams.cl/es/valdivia/book/dates-of-stay',
    ),
    Casino(
      id: '4',
      nombre: 'Dreams Coyhaique',
      ciudad: 'Coyhaique',
      direccion: 'Magallanes 131, Coyhaique',
      latitud: -45.57081,
      longitud: -72.07419,
      imageUrl: 'assets/images/coyhaique.jpg',
      description: 'En el corazón de la Patagonia chilena. Salas de juegos, gastronomía regional, coctelería y eventos.',
      features: ['Patagonia', 'Gastronomía de Autor', 'Ruleta', 'Shows en Vivo'],
      rating: 4.8,
      schedules: {'Lunes-Domingo': '12:00 - 04:00'},
      websiteUrl: 'https://coyhaique.dreams.cl/',
      reservationUrl: 'https://reservations.dreams.cl/es/patagonia/book/dates-of-stay',
    ),
    Casino(
      id: '5',
      nombre: 'Dreams Punta Arenas',
      ciudad: 'Punta Arenas',
      direccion: 'O\'Higgins 1235, Punta Arenas',
      latitud: -53.16614,
      longitud: -70.90611,
      imageUrl: 'assets/images/punta_arenas.jpg',
      description: 'Frente al Estrecho de Magallanes, en el fin del mundo.',
      features: ['Estrecho de Magallanes', 'Restaurante Doña Inés', 'Mirador'],
      rating: 4.5,
      schedules: {'Lunes-Domingo': '12:00 - 05:00'},
      websiteUrl: 'https://punta-arenas.dreams.cl/',
      reservationUrl: 'https://reservations.dreams.cl/es/estrecho/book/dates-of-stay',
    ),
    Casino(
      id: '6',
      nombre: 'Dreams Puerto Varas',
      ciudad: 'Puerto Varas',
      direccion: 'Del Salvador 21, Puerto Varas',
      latitud: -41.3195,
      longitud: -72.9858,
      imageUrl: 'assets/images/puerto_varas.jpg',
      description: 'A orillas del Lago Llanquihue con vista privilegiada a los volcanes Osorno y Calbuco.',
      features: ['Vista Lago Llanquihue', 'Volcanes', 'Gastronomía Alemana'],
      rating: 4.8,
      schedules: {'Lunes-Domingo': '12:00 - 04:00'},
      websiteUrl: 'https://puerto-varas.dreams.cl/',
      reservationUrl: 'https://reservations.dreams.cl/es/volcanes/book/dates-of-stay',
    ),
    Casino(
      id: '7',
      nombre: 'Dreams Monticello',
      ciudad: 'San Francisco de Mostazal',
      direccion: 'Panamericana Sur Km 57, Mostazal',
      latitud: -33.92143,
      longitud: -70.72161,
      imageUrl: 'assets/images/monticello.jpg',
      description: 'El casino y resort más grande de Chile con arena de conciertos internacional.',
      features: ['Arena Monticello', 'Grand Casino', 'Gastronomía Internacional', 'Hotel Resort'],
      rating: 4.9,
      schedules: {'Lunes-Domingo': '24 Horas'},
      websiteUrl: 'https://monticello.dreams.cl/',
      reservationUrl: 'https://reservashotel.mundodreams.com/es',
    ),
    Casino(
      id: '8',
      nombre: 'Dreams Talca (Próximamente)',
      ciudad: 'Talca',
      direccion: 'En construcción - Región del Maule',
      latitud: -35.4264,
      longitud: -71.6554,
      imageUrl: 'assets/images/talca.jpg',
      description: 'Próxima gran apertura del nuevo complejo de entretención en Talca.',
      features: ['En construcción', 'Próximamente', 'Proyecto Dreams'],
      rating: 5.0,
      schedules: {'Próximamente': 'En desarrollo'},
      websiteUrl: 'https://www.dreams.cl/',
      reservationUrl: null,
    ),
  ];

  Future<List<Casino>> getAllCasinos() async {
    return staticCasinos;
  }

  Stream<List<Casino>> watchAllCasinos() {
    return Stream.value(staticCasinos);
  }

  Future<Casino> getNearestCasino(double latitude, double longitude) async {
    final casinos = await getAllCasinos();
    if (casinos.isEmpty) {
      throw Exception(
          'No hay casinos disponibles para determinar el más cercano.');
    }

    Casino nearestCasino = casinos.first;
    double minDistance = double.infinity;

    for (var casino in casinos) {
      final distance = _calculateDistanceKm(
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

  double _calculateDistanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371;
    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Future<Casino> getCasinoById(String id) async {
    final casinos = await getAllCasinos();
    return casinos.firstWhere(
      (casino) => casino.id == id,
      orElse: () => throw Exception('Casino con id $id no encontrado'),
    );
  }
}
