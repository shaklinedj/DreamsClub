
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/models/hotel_model.dart';
import 'package:casinoloyalty_flutter/models/restaurante_model.dart';
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
          ),
          Restaurante(
            id: 2,
            casinoId: 1,
            nombre: 'Doña Inés',
            imageUrl: 'https://images.unsplash.com/photo-1481931715705-36f5f79f1ff4?auto=format&fit=crop&w=1200&q=80',
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
          ),
          Restaurante(
            id: 4,
            casinoId: 2,
            nombre: 'Pichanga',
            imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
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
          ),
          Restaurante(
            id: 6,
            casinoId: 3,
            nombre: 'Sky Bar',
            imageUrl: 'https://images.unsplash.com/photo-1466978913421-dad2ebd01d17?auto=format&fit=crop&w=1200&q=80',
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
          ),
          Restaurante(
            id: 8,
            casinoId: 4,
            nombre: 'Sky Bar',
            imageUrl: 'https://images.unsplash.com/photo-1457460866886-40ef8d4b42a0?auto=format&fit=crop&w=1200&q=80',
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
          ),
          Restaurante(
            id: 10,
            casinoId: 5,
            nombre: 'El Rincón del Chef',
            imageUrl: 'https://images.unsplash.com/photo-1470337458703-46ad1756a187?auto=format&fit=crop&w=1200&q=80',
          ),
          Restaurante(
            id: 11,
            casinoId: 5,
            nombre: 'La Pica de la Esquina',
            imageUrl: 'https://images.unsplash.com/photo-1521305916504-4a1121188589?auto=format&fit=crop&w=1200&q=80',
          ),
          Restaurante(
            id: 14,
            casinoId: 5,
            nombre: 'Buffet Capataz',
            imageUrl: 'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=1200&q=80',
          ),
          Restaurante(
            id: 15,
            casinoId: 5,
            nombre: 'Lucky 7 Bar',
            imageUrl: 'https://images.unsplash.com/photo-1514362545857-3bc16549766b?auto=format&fit=crop&w=1200&q=80',
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
          ),
          Restaurante(
            id: 13,
            casinoId: 6,
            nombre: 'Sky Bar',
            imageUrl: 'https://images.unsplash.com/photo-1552566626-10d0c6462d0d?auto=format&fit=crop&w=1200&q=80',
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
          ),
          Restaurante(
            id: 15,
            casinoId: 7,
            nombre: 'El Fogón',
            imageUrl: 'https://images.unsplash.com/photo-1544148103-0773bf10d330?auto=format&fit=crop&w=1200&q=80',
          ),
        ],
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
}
