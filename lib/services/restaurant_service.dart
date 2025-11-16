import 'package:casinoloyalty_flutter/models/restaurante_model.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';

class RestaurantService {
  final CasinoService _casinoService = CasinoService();

  Future<List<Restaurante>> getRestaurantsByCasinoId(int casinoId) async {
    final casino = await _casinoService.getCasinoById(casinoId);
    return casino.restaurantes ?? [];
  }
}
