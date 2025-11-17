import 'package:flutter/material.dart';

// Enum para los niveles de usuario, con nombres en lowerCamelCase.
enum UserLevel { black, gold, platinum, blue }

class User {
  final String name;
  final String email;
  final String profileImageUrl;
  final UserLevel level;
  final int points;
  final double balance;

  const User({
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.level,
    required this.points,
    required this.balance,
  });

  User copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    UserLevel? level,
    int? points,
    double? balance,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      level: level ?? this.level,
      points: points ?? this.points,
      balance: balance ?? this.balance,
    );
  }

  // Método para obtener el color asociado a cada nivel (útil para la UI)
  Color get levelColor {
    switch (level) {
      case UserLevel.black:
        return Colors.grey[900]!;
      case UserLevel.gold:
        return Colors.amber[700]!;
      case UserLevel.platinum:
        return Colors.grey[400]!;
      case UserLevel.blue:
        return Colors.blue[600]!;
      // No se necesita default porque el enum es exhaustivo
    }
  }

  // Método para obtener el nombre del nivel como texto
  String get levelName {
    switch (level) {
      case UserLevel.black:
        return 'Black';
      case UserLevel.gold:
        return 'Gold';
      case UserLevel.platinum:
        return 'Platinum';
      case UserLevel.blue:
        return 'Blue';
      // No se necesita default porque el enum es exhaustivo
    }
  }
}
