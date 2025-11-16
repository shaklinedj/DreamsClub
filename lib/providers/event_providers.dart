
import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventServiceProvider = Provider((ref) => EventService());

final eventsProvider = FutureProvider.family<List<Event>, int>((ref, casinoId) async {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventsByCasinoId(casinoId);
});

final eventDetailsProvider = FutureProvider.family<Event, int>((ref, eventId) async {
  final eventService = ref.watch(eventServiceProvider);
  return eventService.getEventById(eventId);
});
