import 'package:casinoloyalty_flutter/models/hotel_model.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';

class HotelService {
  final CasinoService _casinoService = CasinoService();

  Future<Hotel?> getHotelByCasinoId(int casinoId) async {
    final casino = await _casinoService.getCasinoById(casinoId);
    return casino.hotel;
  }
}
