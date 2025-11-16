import 'package:casinoloyalty_flutter/models/event_model.dart';

class EventService {
  final Map<int, List<Event>> _events = {
    1: [
      Event(
          id: 1,
          casinoId: 1,
          titulo: 'Concierto en vivo',
          descripcion: 'Disfruta de la mejor música en vivo.',
          fecha: DateTime.now(),
          imageUrl: 'https://picsum.photos/seed/event1/400/300'),
      Event(
          id: 2,
          casinoId: 1,
          titulo: 'Noche de Karaoke',
          descripcion: 'Demuestra tu talento en el escenario.',
          fecha: DateTime.now(),
          imageUrl: 'https://picsum.photos/seed/event2/400/300'),
    ],
    2: [
      Event(
          id: 3,
          casinoId: 2,
          titulo: 'Torneo de Poker',
          descripcion: 'Inscríbete y gana grandes premios.',
          fecha: DateTime.now(),
          imageUrl: 'https://picsum.photos/seed/event3/400/300'),
    ],
  };

  Future<List<Event>> getEventsForCasino(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _events[casinoId] ?? [];
  }
}
