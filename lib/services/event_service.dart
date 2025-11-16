import 'package:casinoloyalty_flutter/models/event_model.dart';

class EventService {
  final List<Event> _mockEvents = [
    // Eventos para Dreams Iquique (casinoId: 1)
    Event(
      id: 101,
      casinoId: 1,
      titulo: 'Noche de Salsa & Bachata',
      descripcion: '¡Ven a bailar toda la noche con nuestra banda en vivo! Clases gratis desde las 21:00.',
      fecha: DateTime.now().add(const Duration(days: 5)),
    ),
    Event(
      id: 102,
      casinoId: 1,
      titulo: 'Tributo a Soda Stereo',
      descripcion: 'Revive los mejores éxitos de la legendaria banda argentina. ¡No te lo puedes perder!',
      fecha: DateTime.now().add(const Duration(days: 12)),
    ),

    // Eventos para Dreams Valdivia (casinoId: 3)
    Event(
      id: 301,
      casinoId: 3,
      titulo: 'Festival de Jazz de Valdivia',
      descripcion: 'Disfruta de tres días del mejor jazz nacional e internacional junto al río.',
      fecha: DateTime.now().add(const Duration(days: 20)),
    ),
  ];

  Future<List<Event>> getEventsForCasino(int casinoId) async {
    // Simula una llamada a la API
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockEvents.where((event) => event.casinoId == casinoId).toList();
  }
}
