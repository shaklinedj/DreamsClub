import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;

  /// Inicializa Firebase
  static Future<void> initialize() async {
    if (!_isInitialized) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
    }
  }

  /// Auth
  static FirebaseAuth get auth => FirebaseAuth.instance;

  /// Firestore
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  /// Storage
  static FirebaseStorage get storage => FirebaseStorage.instance;

  /// Usuario actual
  static User? get currentUser => auth.currentUser;

  /// Stream de cambios de auth
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Sign Out
  static Future<void> signOut() async {
    await auth.signOut();
  }

  // ============================================================
  // MÉTODOS DE UTILIDAD
  // ============================================================

  /// Obtiene todos los documentos de una colección
  static Future<List<Map<String, dynamic>>> getAll(String collection) async {
    try {
      final snapshot = await firestore.collection(collection).get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Agregar ID al mapa
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener datos de $collection: $e');
    }
  }

  /// Obtiene un documento por ID
  static Future<Map<String, dynamic>?> getById(
      String collection, String id) async {
    try {
      final doc = await firestore.collection(collection).doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener registro $id de $collection: $e');
    }
  }

  /// Crea un nuevo documento (con ID automático)
  static Future<String> create(
      String collection, Map<String, dynamic> data) async {
    try {
      final ref = await firestore.collection(collection).add(data);
      return ref.id;
    } catch (e) {
      throw Exception('Error al crear registro en $collection: $e');
    }
  }

  /// Actualiza un documento
  static Future<void> update(
      String collection, String id, Map<String, dynamic> data) async {
    try {
      await firestore.collection(collection).doc(id).update(data);
    } catch (e) {
      throw Exception('Error al actualizar registro $id en $collection: $e');
    }
  }

  /// Elimina un documento
  static Future<void> delete(String collection, String id) async {
    try {
      await firestore.collection(collection).doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar registro $id de $collection: $e');
    }
  }

  /// Sube un archivo a Storage y retorna URL
  static Future<String> uploadFile(String path, dynamic fileData) async {
    try {
      final ref = storage.ref().child(path);
      // Asumiendo fileData es Uint8List o similar. Si es File, usar putFile.
      // Para simplificar, usaremos putData si son bytes.
      // Ajustar según el tipo de dato real que venga.
      await ref.putData(fileData);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Error al subir archivo: $e');
    }
  }
}
