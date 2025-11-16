import 'package:casinoloyalty_flutter/models/casino_model.dart';
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
        imageUrl: 'assets/images/iqq-1.jpg'),
    Casino(
        id: 2,
        nombre: 'Dreams Temuco',
        ciudad: 'Temuco',
        direccion: 'Av. Alemania 0945, Temuco',
        latitud: -38.7359,
        longitud: -72.5904,
        imageUrl: 'assets/images/temuco-1.jpg'),
    Casino(
        id: 3,
        nombre: 'Dreams Valdivia',
        ciudad: 'Valdivia',
        direccion: 'Carampangue 190, Valdivia',
        latitud: -39.8142,
        longitud: -73.2459,
        imageUrl: 'assets/images/vld-1.jpg'),
    Casino(
        id: 4,
        nombre: 'Dreams Punta Arenas',
        ciudad: 'Punta Arenas',
        direccion: 'O\'Higgins 1235, Punta Arenas',
        latitud: -53.1638,
        longitud: -70.9171,
        imageUrl: 'assets/images/pta-a-1.jpg'),
    Casino(
        id: 5,
        nombre: 'Monticello',
        ciudad: 'Mostazal',
        direccion: 'Panamericana Sur, Km. 57, Mostazal',
        latitud: -34.0733,
        longitud: -70.7303,
        imageUrl: 'assets/images/fachada-monticello.jpg'),
    Casino(
        id: 6,
        nombre: 'Dreams Puerto Varas',
        ciudad: 'Puerto Varas',
        direccion: 'Del Salvador 21, Puerto Varas',
        latitud: -41.3204,
        longitud: -72.9839,
        imageUrl: 'assets/images/pto-v-2.jpg'),
    Casino(
        id: 7,
        nombre: 'Dreams Coyhaique',
        ciudad: 'Coyhaique',
        direccion: 'Magallanes 131, Coyhaique',
        latitud: -45.5715,
        longitud: -72.0694,
        imageUrl: 'assets/images/coy-1.jpg'),
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
        casino.latitud, // Corregido
        casino.longitud, // Corregido
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
