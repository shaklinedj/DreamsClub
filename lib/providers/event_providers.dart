import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

final eventsProvider = FutureProvider.family<List<Event>, int>((ref, casinoId) {
  return ref.watch(eventServiceProvider).getEventsByCasinoId(casinoId);
});
