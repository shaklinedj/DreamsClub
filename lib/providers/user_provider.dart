
import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Este provider contendrá la información del usuario "logueado".
// Por ahora, usamos datos de ejemplo fijos (mock).
final userProvider = Provider<User>((ref) {
  return User(
    name: 'John Doe', // Tu nombre de ejemplo
    email: 'john.doe@email.com',
    profileImageUrl: 'assets/images/perfil_imagen.png',
    level: UserLevel.black, // ¡Tu nivel de usuario exclusivo! (Corregido a lowerCamelCase)
    points: 125300, // Puntos de ejemplo
    balance: 750.50, // Saldo de ejemplo
  );
});
