
import 'package:casinoloyalty_flutter/models/event_model.dart';

class EventService {
  final List<Event> _mockEvents = [
    // Events for Casino 1 (Iquique)
    Event(
      id: 1,
      casinoId: 1,
      titulo: 'Concierto en Vivo: Tributo a Soda Stereo',
      descripcion: 'Revive los grandes éxitos de la mítica banda argentina con una de las mejores bandas tributo del país. Una noche llena de rock y nostalgia junto al mar.',
      fecha: DateTime.now().add(const Duration(days: 15)),
      imageUrl: 'https://picsum.photos/seed/event1/800/600',
    ),

    // Events for Casino 2 (Temuco)
    Event(
      id: 2,
      casinoId: 2,
      titulo: 'Noche de Stand-Up Comedy',
      descripcion: 'Prepárate para reír a carcajadas con los mejores comediantes de la escena nacional. Un show imperdible para desconectar y pasar un buen rato.',
      fecha: DateTime.now().add(const Duration(days: 20)),
      imageUrl: 'https://picsum.photos/seed/event2/800/600',
    ),
    Event(
      id: 7,
      casinoId: 2,
      titulo: 'Show de Magia e Ilusionismo',
      descripcion: 'Déjate sorprender por un espectáculo que desafiará tu percepción de la realidad. Magia de cerca, grandes ilusiones y mucho misterio te esperan.',
      fecha: DateTime.now().add(const Duration(days: 25)),
      imageUrl: 'https://picsum.photos/seed/event7/800/600',
    ),

    // Events for Casino 3 (Valdivia)
    Event(
      id: 3,
      casinoId: 3,
      titulo: 'Fiesta Electrónica al Aire Libre',
      descripcion: 'Baila hasta el amanecer en nuestra terraza con vista al río. Los mejores DJs de la escena electrónica nacional e internacional en un evento único.',
      fecha: DateTime.now().add(const Duration(days: 30)),
      imageUrl: 'https://picsum.photos/seed/event3/800/600',
    ),

    // Events for Casino 5 (Monticello)
    Event(
      id: 4,
      casinoId: 5,
      titulo: 'Gran Arena Monticello: Concierto de Luis Fonsi',
      descripcion: 'El ícono de la música latina llega a Gran Arena Monticello para presentar sus grandes éxitos y sus nuevas canciones. ¡Una noche que no podrás olvidar!',
      fecha: DateTime.now().add(const Duration(days: 45)),
      imageUrl: 'https://picsum.photos/seed/event4/800/600',
    ),

    // Events for Casino 6 (Puerto Varas)
    Event(
      id: 5,
      casinoId: 6,
      titulo: 'Cata de Vinos Premium',
      descripcion: 'Descubre los secretos de los mejores vinos de Chile junto a nuestro sommelier experto. Una degustación guiada con maridaje de quesos y charcutería.',
      fecha: DateTime.now().add(const Duration(days: 10)),
      imageUrl: 'https://picsum.photos/seed/event5/800/600',
    ),

    // Events for Casino 7 (Coyhaique)
    Event(
      id: 6,
      casinoId: 7,
      titulo: 'Festival de Jazz de la Patagonia',
      descripcion: 'Disfruta de tres días con lo mejor del jazz nacional e internacional en un entorno natural privilegiado. Conciertos, workshops y jam sessions.',
      fecha: DateTime.now().add(const Duration(days: 60)),
      imageUrl: 'https://picsum.photos/seed/event6/800/600',
    ),
    
    // New Events
    Event(
      id: 8,
      casinoId: 1,
      titulo: 'Torneo de Poker Texas Hold\'em',
      descripcion: 'Demuestra tus habilidades en nuestro torneo mensual de Poker. Grandes premios en efectivo y la oportunidad de clasificar al torneo nacional.',
      fecha: DateTime.now().add(const Duration(days: 5)),
      imageUrl: 'https://picsum.photos/seed/event8/800/600',
    ),
    Event(
      id: 9,
      casinoId: 5,
      titulo: 'Noche de Salsa y Bachata',
      descripcion: 'Ven a bailar con la mejor música latina en vivo. Clases gratuitas para principiantes antes del evento principal.',
      fecha: DateTime.now().add(const Duration(days: 12)),
      imageUrl: 'https://picsum.photos/seed/event9/800/600',
    ),
    Event(
      id: 10,
      casinoId: 3,
      titulo: 'Cena Maridaje con Viña Montes',
      descripcion: 'Una experiencia gastronómica de 5 tiempos maridada con los mejores vinos de Viña Montes. Cupos limitados.',
      fecha: DateTime.now().add(const Duration(days: 18)),
      imageUrl: 'https://picsum.photos/seed/event10/800/600',
    ),
  ];

  Future<List<Event>> getEventsByCasinoId(int casinoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockEvents.where((event) => event.casinoId == casinoId).toList();
  }

    Future<Event> getEventById(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockEvents.firstWhere((event) => event.id == id);
  }
}
