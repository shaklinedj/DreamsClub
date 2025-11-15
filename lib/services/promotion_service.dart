import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:dio/dio.dart';

class PromotionService {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:3000/api';

  Future<List<Promotion>> getPromotionsByCasino(int casinoId) async {
    try {
      final response = await _dio.get('$_baseUrl/promotions?casinoId=$casinoId');
      final data = response.data as List;
      return data.map((promotion) => Promotion.fromJson(promotion)).toList();
    } catch (e) {
      throw Exception('Failed to load promotions');
    }
  }
}
