import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casinoloyalty_flutter/models/casino_model.dart';

class AdminCasinoRepository {
  final _db = FirebaseFirestore.instance;

  // --- LEER ---
  Stream<List<Casino>> watchCasinos() {
    return _db.collection('casinos').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Casino.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<Casino>> getCasinos() async {
    final snapshot = await _db.collection('casinos').get();
    return snapshot.docs
        .map((doc) => Casino.fromMap(doc.data(), doc.id))
        .toList();
  }

  // --- ESCRIBIR ---
  Future<void> createCasino(Casino casino) async {
    if (casino.id.isEmpty) {
      // Generate sequential ID for new casinos
      final snapshot = await _db.collection('casinos').get();
      final newId = (snapshot.docs.length + 1).toString();
      await _db.collection('casinos').doc(newId).set(casino.toMap());
    } else {
      await _db.collection('casinos').doc(casino.id).set(casino.toMap());
    }
  }

  Future<void> updateCasino(Casino casino) async {
    await _db.collection('casinos').doc(casino.id).update(casino.toMap());
  }

  Future<void> deleteCasino(String casinoId) async {
    await _db.collection('casinos').doc(casinoId).delete();
  }

  // --- BOOTSTRAP (MIGRACIÓN DE DATOS INICIALES A FIRESTORE) ---
  /// Seeds initial casinos. Set [forceReseed] to true to delete existing and reseed.
  Future<void> seedInitialCasinos({bool forceReseed = false}) async {
    if (forceReseed) {
      // Delete all existing casinos
      final existing = await _db.collection('casinos').get();
      final batch = _db.batch();
      for (var doc in existing.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } else {
      final snapshot = await _db.collection('casinos').limit(1).get();
      if (snapshot.docs.isNotEmpty) return; // Ya hay datos
    }

    final batch = _db.batch();

    final initialCasinos = [
      Casino(
        id: '1',
        nombre: 'Dreams Iquique',
        ciudad: 'Iquique',
        direccion: 'Av. Arturo Prat 2755, Iquique',
        latitud: -20.2122,
        longitud: -70.1524,
        imageUrl: 'assets/images/iqq.jpg',
        description: 'A pasos de playa Cavancha, diversión frente al mar.',
        features: ['Playa Cavancha', 'Shows en Vivo', 'Gastronomía'],
        rating: 4.6,
        schedules: {'Lunes-Domingo': '24 hrs'},
      ),
      Casino(
        id: '2',
        nombre: 'Dreams Temuco',
        ciudad: 'Temuco',
        direccion: 'Av. Alemania 0945, Temuco',
        latitud: -38.7359,
        longitud: -72.5904,
        imageUrl: 'assets/images/temuco.jpg',
        description: 'En el corazón de la Araucanía, lujo y cultura.',
        features: ['Spa Hydra', 'Centro de Eventos', 'Hotel Dreams'],
        rating: 4.7,
        schedules: {'Lunes-Domingo': '24 hrs'},
      ),
      Casino(
        id: '3',
        nombre: 'Dreams Valdivia',
        ciudad: 'Valdivia',
        direccion: 'Av. Costanera Arturo Prat 0795, Valdivia',
        latitud: -39.8142,
        longitud: -73.2459,
        imageUrl: 'assets/images/valdivia.jpg',
        description:
            'A orillas del río Calle-Calle, naturaleza y entretenimiento.',
        features: ['Vista al Río', 'Restaurante Gourmet', 'Sala de Eventos'],
        rating: 4.5,
        schedules: {'Lunes-Domingo': '24 hrs'},
      ),
      Casino(
        id: '4',
        nombre: 'Dreams Coyhaique',
        ciudad: 'Coyhaique',
        direccion: 'Av. Baquedano 315, Coyhaique',
        latitud: -45.5712,
        longitud: -72.0685,
        imageUrl: 'assets/images/coyhaique.jpg',
        description: 'En la Patagonia chilena, aventura y diversión.',
        features: ['Patagonia', 'Gastronomía Regional', 'Torneos'],
        rating: 4.4,
        schedules: {'Lunes-Domingo': '12:00 - 04:00'},
      ),
      Casino(
        id: '5',
        nombre: 'Dreams Punta Arenas',
        ciudad: 'Punta Arenas',
        direccion: 'Av. Colón 556, Punta Arenas',
        latitud: -53.1638,
        longitud: -70.9171,
        imageUrl: 'assets/images/punta_arenas.jpg',
        description: 'El casino más austral del mundo, experiencia única.',
        features: ['Fin del Mundo', 'Hotel 5 Estrellas', 'Centro de Eventos'],
        rating: 4.8,
        schedules: {'Lunes-Domingo': '24 hrs'},
      ),
      Casino(
        id: '6',
        nombre: 'Dreams Puerto Varas',
        ciudad: 'Puerto Varas',
        direccion: 'Del Salvador 21, Puerto Varas',
        latitud: -41.3167,
        longitud: -72.9833,
        imageUrl: 'assets/images/puerto_varas.jpg',
        description: 'Frente al lago Llanquihue con vista al volcán Osorno.',
        features: ['Vista al Lago', 'Volcán Osorno', 'Hotel Radisson'],
        rating: 4.7,
        schedules: {'Lunes-Domingo': '24 hrs'},
      ),
      Casino(
        id: '7',
        nombre: 'Monticello Gran Casino',
        ciudad: 'San Francisco de Mostazal',
        direccion: 'Ruta 5 Sur Km 59, San Francisco de Mostazal',
        latitud: -33.9833,
        longitud: -70.7000,
        imageUrl: 'assets/images/monticello.jpg',
        description: 'El casino más grande de Sudamérica, cerca de Santiago.',
        features: ['Hipódromo', 'Centro de Eventos', 'Gastronomía Premium'],
        rating: 4.7,
        schedules: {'Lunes-Domingo': '24 hrs'},
      ),
    ];

    for (var casino in initialCasinos) {
      final docRef = _db.collection('casinos').doc(casino.id);
      batch.set(docRef, casino.toMap());
    }

    await batch.commit();
  }
}
