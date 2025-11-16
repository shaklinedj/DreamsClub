import 'package:casinoloyalty_flutter/models/event_model.dart';

class EventService {
  final List<Event> _mockEvents = [
    // Eventos para Monticello (casinoId: 5)
    Event(
      id: 501,
      casinoId: 5,
      titulo: 'Kylie Minogue - Tension Tour 2025',
      descripcion:
          'La superestrella australiana llega a Gran Arena Monticello con su espectacular gira mundial.',
      fecha: DateTime.now().add(const Duration(days: 45)),
    ),
    Event(
      id: 502,
      casinoId: 5,
      titulo: 'Ke Personajes',
      descripcion:
          'La banda de cumbia del momento se presenta con todos sus éxitos. ¡Una fiesta imperdible!',
      fecha: DateTime.now().add(const Duration(days: 60)),
    ),
    Event(
      id: 503,
      casinoId: 5,
      titulo: 'Los Vásquez - 15 Años',
      descripcion:
          'Celebra los 15 años de carrera del dúo pop cebolla más querido de Chile.',
      fecha: DateTime.now().add(const Duration(days: 75)),
    ),

    // Eventos para Dreams Iquique (casinoId: 1)
    Event(
      id: 101,
      casinoId: 1,
      titulo: 'Especial Halloween con la banda Black Star',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 1)),
    ),
    Event(
      id: 102,
      casinoId: 1,
      titulo: 'Especial Halloween con la banda Black Star',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 2)),
    ),
    Event(
      id: 103,
      casinoId: 1,
      titulo:
          'Conmemoración día del funcionario municipal con la banda Mr. Pailos',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 8)),
    ),
    Event(
      id: 104,
      casinoId: 1,
      titulo: 'Especial Clásicos AM con la banda Moby Dick',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 9)),
    ),
    Event(
      id: 105,
      casinoId: 1,
      titulo: 'Especial Manuel Mijares con la banda Moby Dick',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 15)),
    ),
    Event(
      id: 106,
      casinoId: 1,
      titulo: 'Especial Gilda con la banda Moby Dick',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 16)),
    ),
    Event(
      id: 107,
      casinoId: 1,
      titulo: 'Especial Vilma Palma e Vampiros con la banda Moby Dick',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 22)),
    ),
    Event(
      id: 108,
      casinoId: 1,
      titulo: 'Especial Soda Stereo con la banda Moby Dick',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 23)),
    ),
    Event(
      id: 109,
      casinoId: 1,
      titulo: 'Especial Creedence con la banda Moby Dick',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 29)),
    ),
    Event(
      id: 110,
      casinoId: 1,
      titulo: 'Especial Studio 54 con la banda Moby Dick',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 30)),
    ),

    // Eventos para Dreams Temuco (casinoId: 2)
    Event(
      id: 201,
      casinoId: 2,
      titulo: 'Especial Halloween con la banda Blackout',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 1)),
    ),
    Event(
      id: 202,
      casinoId: 2,
      titulo: 'Especial Halloween con la banda Blackout',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 2)),
    ),
    Event(
      id: 203,
      casinoId: 2,
      titulo: 'Especial 80s con la banda vinilo',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 8)),
    ),
    Event(
      id: 204,
      casinoId: 2,
      titulo: 'Especial Raphael con la banda La Clave',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 9)),
    ),
    Event(
      id: 205,
      casinoId: 2,
      titulo: 'Especial Cristian Castro con la banda La Clave',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 15)),
    ),
    Event(
      id: 206,
      casinoId: 2,
      titulo: 'Especial Pimpinela con la banda La Clave',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 16)),
    ),
    Event(
      id: 207,
      casinoId: 2,
      titulo: 'Especial Rock Latino con la banda La Clave',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 22)),
    ),
    Event(
      id: 208,
      casinoId: 2,
      titulo: 'Especial Juan Gabriel con la banda La Clave',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 23)),
    ),
    Event(
      id: 209,
      casinoId: 2,
      titulo: 'Especial rock en español con la banda La Clave',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 29)),
    ),
    Event(
      id: 210,
      casinoId: 2,
      titulo: 'Especial fiesta ochentera con la banda La Clave',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 30)),
    ),

    // Eventos para Dreams Valdivia (casinoId: 3)
    Event(
      id: 301,
      casinoId: 3,
      titulo: 'Especial Halloween con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 1)),
    ),
    Event(
      id: 302,
      casinoId: 3,
      titulo: 'Especial Halloween con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 2)),
    ),
    Event(
      id: 303,
      casinoId: 3,
      titulo: 'Especial 80s con la banda vinilo',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 8)),
    ),
    Event(
      id: 304,
      casinoId: 3,
      titulo: 'Especial Raphael con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 9)),
    ),
    Event(
      id: 305,
      casinoId: 3,
      titulo: 'Especial Cristian Castro con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 15)),
    ),
    Event(
      id: 306,
      casinoId: 3,
      titulo: 'Especial Pimpinela con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 16)),
    ),
    Event(
      id: 307,
      casinoId: 3,
      titulo: 'Especial Rock Latino con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 22)),
    ),
    Event(
      id: 308,
      casinoId: 3,
      titulo: 'Especial Juan Gabriel con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 23)),
    ),
    Event(
      id: 309,
      casinoId: 3,
      titulo: 'Especial rock en español con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 29)),
    ),
    Event(
      id: 310,
      casinoId: 3,
      titulo: 'Especial fiesta ochentera con la banda Frecuencia',
      descripcion: 'Show gratis con tu entrada a casino',
      fecha: DateTime.now().add(const Duration(days: 30)),
    ),
  ];

  Future<List<Event>> getEventsForCasino(int casinoId) async {
    // Simula una llamada a la API
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockEvents.where((event) => event.casinoId == casinoId).toList();
  }
}
