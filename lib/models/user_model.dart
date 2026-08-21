import 'package:flutter/material.dart';

// Enum para los niveles de usuario, con nombres en lowerCamelCase.
enum UserLevel { black, gold, platinum, blue }

class User {
  final String name;
  final String email;
  final String profileImageUrl;
  final UserLevel level;
  final int points;
  final int balance;
  final bool isAdmin;

  final String? rut;
  final String? pin;
  final String? favoriteCasinoId;
  final DateTime? birthday;
  final bool notificationsEnabled;
  final bool locationTrackingEnabled;
  final int streak;
  final int totalVisits;
  final bool wantsContact;
  final String? phoneNumber;

  const User({
    required this.name,
    required this.email,
    required this.profileImageUrl,
    required this.level,
    required this.points,
    required this.balance,
    this.rut,
    this.pin,
    this.isAdmin = false,
    this.favoriteCasinoId,
    this.birthday,
    this.notificationsEnabled = true,
    this.locationTrackingEnabled = true,
    this.streak = 0,
    this.totalVisits = 0,
    this.wantsContact = false,
    this.phoneNumber,
  });

  User copyWith({
    String? name,
    String? email,
    String? profileImageUrl,
    UserLevel? level,
    int? points,
    int? balance,
    String? rut,
    String? pin,
    bool? isAdmin,
    String? favoriteCasinoId,
    DateTime? birthday,
    bool? notificationsEnabled,
    bool? locationTrackingEnabled,
    int? streak,
    int? totalVisits,
    bool? wantsContact,
    String? phoneNumber,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      level: level ?? this.level,
      points: points ?? this.points,
      balance: balance ?? this.balance,
      rut: rut ?? this.rut,
      pin: pin ?? this.pin,
      isAdmin: isAdmin ?? this.isAdmin,
      favoriteCasinoId: favoriteCasinoId ?? this.favoriteCasinoId,
      birthday: birthday ?? this.birthday,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationTrackingEnabled:
          locationTrackingEnabled ?? this.locationTrackingEnabled,
      streak: streak ?? this.streak,
      totalVisits: totalVisits ?? this.totalVisits,
      wantsContact: wantsContact ?? this.wantsContact,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  // Método para obtener el color asociado a cada nivel (útil para la UI)
  Color get levelColor {
    switch (level) {
      case UserLevel.black:
        return Colors.white; // Maximum visibility for Black level accents
      case UserLevel.gold:
        return Colors.amber[700]!;
      case UserLevel.platinum:
        return Colors.grey[400]!;
      case UserLevel.blue:
        return Colors.blue[600]!;
      // No se necesita default porque el enum es exhaustivo
    }
  }

  // Método para obtener el color de texto que contrasta con el color de nivel
  Color get levelTextColor {
    switch (level) {
      case UserLevel.black:
        return Colors.black; // Text color on white background
      case UserLevel.gold:
        return Colors.black; // Texto negro sobre fondo dorado
      case UserLevel.platinum:
        return Colors.black; // Texto negro sobre fondo platino
      case UserLevel.blue:
        return Colors.white; // Texto blanco sobre fondo azul
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
    }
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] ?? map['displayName'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profile_image_url'] ?? '',
      level: _parseUserLevel(map['level']),
      points: map['points']?.toInt() ?? 0,
      balance: map['balance']?.toInt() ?? 0,
      rut: map['rut'],
      pin: map['pin'],
      isAdmin: map['isAdmin'] ?? false,
      favoriteCasinoId: map['favoriteCasinoId'],
      birthday: map['birthday'] != null
          ? (map['birthday'] is String
              ? DateTime.tryParse(map['birthday'])
              : (map['birthday'] as dynamic).toDate())
          : null,
      notificationsEnabled: map['notifications_enabled'] ?? true,
      locationTrackingEnabled: map['location_tracking_enabled'] ?? true,
      streak: map['currentStreak']?.toInt() ?? map['streak']?.toInt() ?? 0,
      totalVisits: map['totalVisits']?.toInt() ?? 0,
      wantsContact: map['wantsContact'] ?? map['wants_contact'] ?? false,
      phoneNumber: map['phoneNumber'] ?? map['phone_number'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profile_image_url': profileImageUrl,
      'level': level.name, // Saves as 'black', 'gold', etc.
      'points': points,
      'balance': balance,
      'rut': rut,
      'pin': pin,
      'isAdmin': isAdmin,
      'favoriteCasinoId': favoriteCasinoId,
      'birthday': birthday?.toIso8601String(),
      'notifications_enabled': notificationsEnabled,
      'location_tracking_enabled': locationTrackingEnabled,
      'streak': streak,
      'currentStreak': streak,
      'totalVisits': totalVisits,
      'wantsContact': wantsContact,
      'phoneNumber': phoneNumber,
    };
  }

  static UserLevel _parseUserLevel(String? levelName) {
    if (levelName == null) return UserLevel.blue;
    try {
      return UserLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == levelName.toLowerCase(),
        orElse: () => UserLevel.blue,
      );
    } catch (_) {
      return UserLevel.blue;
    }
  }
}
