import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../firebase_service.dart';

/// Servicio API para operaciones de usuarios
class UserApiService {
  static const String _table = 'users';
  static const String _visitsTable = 'user_visits';
  static const String _pointsTable = 'user_points_history';

  /// Obtiene el perfil del usuario actual
  static Future<User?> getCurrentUserProfile() async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return null;

      final response = await FirebaseService.getById(_table, userId);

      if (response == null) return null;
      return _userFromJson(response);
    } catch (e) {
      throw Exception('Error al obtener perfil de usuario: $e');
    }
  }

  /// Obtiene un usuario por ID
  static Future<User?> getUserById(String userId) async {
    try {
      final response = await FirebaseService.getById(_table, userId);

      if (response == null) return null;
      return _userFromJson(response);
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Crea o actualiza el perfil de usuario
  static Future<User> upsertUserProfile(User user) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final data = {
        'id': userId,
        'name': user.name,
        'email': user.email,
        'profile_image_url': user.profileImageUrl,
        'level': user.level.name,
        'points': user.points,
        'balance': user.balance,
        'favorite_casino_id': user.favoriteCasinoId,
        'birthday': user.birthday?.toIso8601String(),
        'notifications_enabled': user.notificationsEnabled,
        'location_tracking_enabled': user.locationTrackingEnabled,
      };

      // Firestore: set con merge: true actúa como upsert
      await FirebaseService.firestore
          .collection(_table)
          .doc(userId)
          .set(data, SetOptions(merge: true));

      return user;
    } catch (e) {
      throw Exception('Error al guardar perfil de usuario: $e');
    }
  }

  /// Actualiza los puntos del usuario
  static Future<void> updateUserPoints(int points) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Use upsert to avoid failures when user doc doesn't exist yet
      await FirebaseService.firestore
          .collection(_table)
          .doc(userId)
          .set({'points': points}, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error al actualizar puntos: $e');
    }
  }

  /// Agrega puntos al usuario (incremento relativo)
  static Future<void> addPoints(int points, String reason) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      // Incrementar puntos usando FieldValue.increment
      await FirebaseService.firestore.collection(_table).doc(userId).set(
        {
          'id': userId,
          'points': FieldValue.increment(points),
        },
        SetOptions(merge: true),
      );

      // Registrar historial (opcional, pero recomendado)
      await FirebaseService.create(_pointsTable, {
        'user_id': userId,
        'points': points,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al agregar puntos: $e');
    }
  }

  /// Actualiza el balance del usuario
  static Future<void> updateUserBalance(double balance) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      await FirebaseService.update(_table, userId, {'balance': balance});
    } catch (e) {
      throw Exception('Error al actualizar balance: $e');
    }
  }

  /// Registra una visita a un casino
  static Future<void> recordCasinoVisit(int casinoId) async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) throw Exception('Usuario no autenticado');

      await FirebaseService.create(_visitsTable, {
        'user_id': userId,
        'casino_id': casinoId,
        'visited_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al registrar visita: $e');
    }
  }

  /// Obtiene el historial de visitas del usuario
  static Future<List<Map<String, dynamic>>> getUserVisits() async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await FirebaseService.firestore
          .collection(_visitsTable)
          .where('user_id', isEqualTo: userId)
          .orderBy('visited_at', descending: true)
          .limit(50)
          .get();

      // Nota: Firestore no soporta joins. Si se necesita info del casino,
      // se debe obtener por separado o denormalizar datos al guardar.
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Obtiene el historial de puntos del usuario
  static Future<List<Map<String, dynamic>>> getPointsHistory() async {
    try {
      final userId = FirebaseService.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await FirebaseService.firestore
          .collection(_pointsTable)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      return [];
    }
  }

  /// Convierte JSON a modelo User
  static User _userFromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profile_image_url'] ?? '',
      level: _parseLevelFromString(json['level']),
      points: json['points'] ?? 0,
      balance: (json['balance'] ?? 0.0).toDouble(),
      favoriteCasinoId: json['favorite_casino_id'],
      birthday:
          json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      locationTrackingEnabled: json['location_tracking_enabled'] ?? true,
    );
  }

  /// Convierte string a UserLevel enum
  static UserLevel _parseLevelFromString(String? level) {
    switch (level?.toLowerCase()) {
      case 'black':
        return UserLevel.black;
      case 'gold':
        return UserLevel.gold;
      case 'platinum':
        return UserLevel.platinum;
      case 'blue':
        return UserLevel.blue;
      default:
        return UserLevel.blue;
    }
  }
}
