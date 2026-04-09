import 'package:casinoloyalty_flutter/data/repositories/admin_casino_repository.dart';
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:geolocator/geolocator.dart';

class CasinoService {
  final _repository = AdminCasinoRepository();

  // Mantiene compatibilidad con la app existente
  Future<List<Casino>> getAllCasinos() async {
    // Intentar seed si está vacío (solo la primera vez)
    await _repository.seedInitialCasinos();
    return _repository.getCasinos();
  }

  // Retorna un Stream para actualizaciones en tiempo real
  Stream<List<Casino>> watchAllCasinos() {
    return _repository.watchCasinos();
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

  Future<Casino> getCasinoById(String id) async {
    final casinos = await getAllCasinos();
    return casinos.firstWhere(
      (casino) => casino.id == id,
      orElse: () => throw Exception('Casino con id $id no encontrado'),
    );
  }
}
