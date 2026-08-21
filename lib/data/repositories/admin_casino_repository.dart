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
      final snapshot = await _db.collection('casinos').get();
      if (snapshot.docs.isNotEmpty) {
        // Buscar el documento de Coyhaique ('4')
        final coyDoc = snapshot.docs.cast<DocumentSnapshot?>().firstWhere(
              (doc) => doc?.id == '4',
              orElse: () => null,
            );
        final data = coyDoc?.data() as Map<String, dynamic>?;
        final address = data?['direccion'] as String?;
        final lat = data?['latitud'] as num?;

        // Si la dirección o la latitud no corresponden a la versión corregida,
        // forzar la actualización de toda la colección.
        if (address != 'Magallanes 131, Coyhaique' || lat == -45.5712) {
          await seedInitialCasinos(forceReseed: true);
        }
        return; // Ya hay datos actualizados
      }
    }

    final batch = _db.batch();

    const initialCasinos = [
      Casino(
        id: '4',
        nombre: 'Dreams Coyhaique',
        ciudad: 'Coyhaique',
        direccion: 'Magallanes 131, Coyhaique',
        latitud: -45.57081,
        longitud: -72.07419,
        imageUrl: 'assets/images/coyhaique.jpg',
        description: 'En el corazón de la Patagonia chilena. Salas de juegos, gastronomía regional, coctelería y eventos.',
        features: ['Patagonia', 'Gastronomía de Autor', 'Ruleta', 'Shows en Vivo'],
        rating: 4.8,
        schedules: {'Lunes-Domingo': '12:00 - 04:00'},
      ),
      Casino(
        id: '1',
        nombre: 'Dreams Iquique',
        ciudad: 'Iquique',
        direccion: 'Av. Arturo Prat 2755, Iquique',
        latitud: -20.23528,
        longitud: -70.14722,
        imageUrl: 'assets/images/iqq.jpg',
        description: 'Frente a Playa Brava, vistas al Pacífico y entretenimiento de primer nivel.',
        features: ['Playa Brava', 'Hotel 5 Estrellas', 'Spa & Piscina', 'Buffet'],
        rating: 4.6,
        schedules: {'Lunes-Domingo': '24 Horas'},
      ),
      Casino(
        id: '2',
        nombre: 'Dreams Temuco',
        ciudad: 'Temuco',
        direccion: 'Av. Alemania 0945, Temuco',
        latitud: -38.73315,
        longitud: -72.61541,
        imageUrl: 'assets/images/temuco.jpg',
        description: 'El centro de entretenimiento más grande de la Araucanía.',
        features: ['Centro de Convenciones', 'Restaurante In', 'Sky Bar', 'Shows'],
        rating: 4.5,
        schedules: {'Lunes-Domingo': '10:00 - 05:00'},
      ),
      Casino(
        id: '3',
        nombre: 'Dreams Valdivia',
        ciudad: 'Valdivia',
        direccion: 'Carampangue 190, Valdivia',
        latitud: -39.8113,
        longitud: -73.24611,
        imageUrl: 'assets/images/valdivia.jpg',
        description: 'A orillas del Río Calle-Calle con arquitectura icónica y gastronomía fluvial.',
        features: ['Vista al Río', 'Sky Bar 360', 'Cervecería Artesanal', 'Hotel'],
        rating: 4.7,
        schedules: {'Lunes-Domingo': '12:00 - 04:00'},
      ),
      Casino(
        id: '5',
        nombre: 'Dreams Punta Arenas',
        ciudad: 'Punta Arenas',
        direccion: 'O\'Higgins 1235, Punta Arenas',
        latitud: -53.16614,
        longitud: -70.90611,
        imageUrl: 'assets/images/punta_arenas.jpg',
        description: 'Frente al Estrecho de Magallanes, en el fin del mundo.',
        features: ['Estrecho de Magallanes', 'Restaurante Doña Inés', 'Mirador'],
        rating: 4.5,
        schedules: {'Lunes-Domingo': '12:00 - 05:00'},
      ),
      Casino(
        id: '6',
        nombre: 'Dreams Puerto Varas',
        ciudad: 'Puerto Varas',
        direccion: 'Del Salvador 21, Puerto Varas',
        latitud: -41.3195,
        longitud: -72.9858,
        imageUrl: 'assets/images/puerto_varas.jpg',
        description: 'A orillas del Lago Llanquihue con vista privilegiada a los volcanes Osorno y Calbuco.',
        features: ['Vista Lago Llanquihue', 'Volcanes', 'Gastronomía Alemana'],
        rating: 4.8,
        schedules: {'Lunes-Domingo': '12:00 - 04:00'},
      ),
      Casino(
        id: '7',
        nombre: 'Monticello',
        ciudad: 'San Francisco de Mostazal',
        direccion: 'Panamericana Sur Km 57, Mostazal',
        latitud: -33.92143,
        longitud: -70.72161,
        imageUrl: 'assets/images/monticello.jpg',
        description: 'El casino y resort más grande de Chile con arena de conciertos internacional.',
        features: ['Arena Monticello', 'Grand Casino', 'Gastronomía Internacional', 'Hotel Resort'],
        rating: 4.9,
        schedules: {'Lunes-Domingo': '24 Horas'},
      ),
    ];

    for (var casino in initialCasinos) {
      final docRef = _db.collection('casinos').doc(casino.id);
      batch.set(docRef, casino.toMap());
    }

    await batch.commit();
  }
}
