import '../../models/casino_model.dart';
import '../firebase_service.dart';

/// Servicio API para operaciones de casinos
class CasinoApiService {
  static const String _table = 'casinos';

  /// Obtiene todos los casinos
  static Future<List<Casino>> getCasinos() async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection(_table)
          .orderBy('nombre')
          .get();

      return snapshot.docs.map((d) => Casino.fromJson(d.data())).toList();
    } catch (e) {
      throw Exception('Error al obtener casinos: $e');
    }
  }

  /// Obtiene un casino por ID
  static Future<Casino?> getCasinoById(String id) async {
    try {
      final doc =
          await FirebaseService.firestore.collection(_table).doc(id).get();

      if (!doc.exists) return null;
      return Casino.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Error al obtener casino $id: $e');
    }
  }

  /// Obtiene casinos por ciudad
  static Future<List<Casino>> getCasinosByCity(String city) async {
    try {
      final snapshot = await FirebaseService.firestore
          .collection(_table)
          .where('ciudad', isEqualTo: city)
          .orderBy('nombre')
          .get();

      return snapshot.docs.map((d) => Casino.fromJson(d.data())).toList();
    } catch (e) {
      throw Exception('Error al obtener casinos de $city: $e');
    }
  }

  /// Crea un nuevo casino (admin)
  static Future<Casino> createCasino(Map<String, dynamic> data) async {
    try {
      final newId = await FirebaseService.create(_table, data);
      final created = await FirebaseService.getById(_table, newId);
      if (created == null) throw Exception('Error al leer casino creado');
      return Casino.fromJson(created);
    } catch (e) {
      throw Exception('Error al crear casino: $e');
    }
  }

  /// Actualiza un casino (admin)
  static Future<Casino> updateCasino(
      String id, Map<String, dynamic> data) async {
    try {
      await FirebaseService.update(_table, id, data);
      final updated = await getCasinoById(id);
      if (updated == null) {
        throw Exception('Casino no encontrado tras actualizar');
      }
      return updated;
    } catch (e) {
      throw Exception('Error al actualizar casino: $e');
    }
  }

  /// Elimina un casino (admin)
  static Future<void> deleteCasino(String id) async {
    try {
      await FirebaseService.delete(_table, id);
    } catch (e) {
      throw Exception('Error al eliminar casino: $e');
    }
  }
}
