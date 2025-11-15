import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:dio/dio.dart';

class EventService {
  final Dio _dio = Dio();
  final String _baseUrl = 'http://localhost:3000/api';

  Future<List<Event>> getEventsByCasino(int casinoId) async {
    try {
      final response = await _dio.get('$_baseUrl/events?casinoId=$casinoId');
      final data = response.data as List;
      return data.map((event) => Event.fromJson(event)).toList();
    } catch (e) {
      throw Exception('Failed to load events');
    }
  }
}
