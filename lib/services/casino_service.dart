import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class CasinoService {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:3000/api';

  Future<List<Casino>> getAllCasinos() async {
    try {
      final response = await _dio.get('$_baseUrl/casinos');
      final data = response.data as List;
      return data.map((casino) => Casino.fromJson(casino)).toList();
    } catch (e) {
      throw Exception('Failed to load casinos');
    }
  }

  Future<Casino> getNearestCasino(double latitude, double longitude) async {
    final casinos = await getAllCasinos();
    Casino nearestCasino = casinos.first;
    double minDistance = double.infinity;

    for (var casino in casinos) {
      double distance = Geolocator.distanceBetween(
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
}
