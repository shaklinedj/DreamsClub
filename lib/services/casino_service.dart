
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
        hotel: Hotel(id: '1', casinoId: '1', nombre: 'Hotel Dreams Iquique', imageUrl: 'https://iquique.dreams.cl/wp-content/uploads/2021/09/hotel-1-1.jpg'),
        restaurantes: [
          Restaurante(id: '1', casinoId: '1', nombre: 'La Pampa', imageUrl: 'https://media-cdn.tripadvisor.com/media/photo-s/0a/01/29/73/la-pampa.jpg'),
          Restaurante(id: '2', casinoId: '1', nombre: 'Doña Inés', imageUrl: 'https://media-cdn.tripadvisor.com/media/photo-s/0a/01/29/73/la-pampa.jpg'),
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
        hotel: Hotel(id: '2', casinoId: '2', nombre: 'Hotel Dreams Temuco', imageUrl: 'https://temuco.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
        restaurantes: [
          Restaurante(id: '3', casinoId: '2', nombre: 'In', imageUrl: 'https://temuco.dreams.cl/wp-content/uploads/2021/10/in-1.jpg'),
          Restaurante(id: '4', casinoId: '2', nombre: 'Pichanga', imageUrl: 'https://temuco.dreams.cl/wp-content/uploads/2021/10/pichanga-1.jpg'),
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
        hotel: Hotel(id: '3', casinoId: '3', nombre: 'Hotel Dreams Valdivia', imageUrl: 'https://valdivia.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
        restaurantes: [
          Restaurante(id: '5', casinoId: '3', nombre: 'Doña Inés', imageUrl: 'https://valdivia.dreams.cl/wp-content/uploads/2021/10/dona-ines-1.jpg'),
          Restaurante(id: '6', casinoId: '3', nombre: 'Sky Bar', imageUrl: 'https://valdivia.dreams.cl/wp-content/uploads/2021/10/sky-bar-1.jpg'),
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
        hotel: Hotel(id: '4', casinoId: '4', nombre: 'Hotel Dreams Punta Arenas', imageUrl: 'https://punta-arenas.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
        restaurantes: [
          Restaurante(id: '7', casinoId: '4', nombre: 'Doña Inés', imageUrl: 'https://punta-arenas.dreams.cl/wp-content/uploads/2021/10/dona-ines-1.jpg'),
          Restaurante(id: '8', casinoId: '4', nombre: 'Sky Bar', imageUrl: 'https://punta-arenas.dreams.cl/wp-content/uploads/2021/10/sky-bar-1.jpg'),
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
        hotel: Hotel(id: '5', casinoId: '5', nombre: 'Hotel Monticello', imageUrl: 'https://www.monticello.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
        restaurantes: [
          Restaurante(id: '9', casinoId: '5', nombre: 'El Pescador', imageUrl: 'https://www.monticello.cl/wp-content/uploads/2021/10/el-pescador-1.jpg'),
          Restaurante(id: '10', casinoId: '5', nombre: 'El Rincón del Chef', imageUrl: 'https://www.monticello.cl/wp-content/uploads/2021/10/el-rincon-del-chef-1.jpg'),
          Restaurante(id: '11', casinoId: '5', nombre: 'La Pica de la Esquina', imageUrl: 'https://www.monticello.cl/wp-content/uploads/2021/10/la-pica-de-la-esquina-1.jpg'),
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
        hotel: Hotel(id: '6', casinoId: '6', nombre: 'Hotel Dreams Puerto Varas', imageUrl: 'https://puerto-varas.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
        restaurantes: [
          Restaurante(id: '12', casinoId: '6', nombre: 'Doña Inés', imageUrl: 'https://puerto-varas.dreams.cl/wp-content/uploads/2021/10/dona-ines-1.jpg'),
          Restaurante(id: '13', casinoId: '6', nombre: 'Sky Bar', imageUrl: 'https://puerto-varas.dreams.cl/wp-content/uploads/2021/10/sky-bar-1.jpg'),
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
        hotel: Hotel(id: '7', casinoId: '7', nombre: 'Hotel Dreams Coyhaique', imageUrl: 'https://coyhaique.dreams.cl/wp-content/uploads/2021/09/hotel-1.jpg'),
        restaurantes: [
          Restaurante(id: '14', casinoId: '7', nombre: 'Donde el Chef', imageUrl: 'https://coyhaique.dreams.cl/wp-content/uploads/2021/10/donde-el-chef-1.jpg'),
          Restaurante(id: '15', casinoId: '7', nombre: 'El Fogón', imageUrl: 'https://coyhaique.dreams.cl/wp-content/uploads/2021/10/el-fogon-1.jpg'),
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
