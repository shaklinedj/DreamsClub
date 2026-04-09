import 'package:cloud_firestore/cloud_firestore.dart';

enum GameFrequency { daily, weekly, unlimited, oncePerStay }

class GameConfig {
  final String gameId; // 'dreams_mania', 'roulette', 'slots'
  final String title;
  final bool isActive; // Master switch
  final bool requiresLocation; // Geo-fencing
  final GameFrequency frequency;
  final List<int> activeWeekdays; // 1=Monday, 7=Sunday. Empty = all days.
  final DateTime? validFrom;
  final DateTime? validUntil;

  // Allowed user levels (empty = all levels allowed)
  // Values: 'black', 'gold', 'platinum', 'blue'
  final List<String> allowedUserLevels;

  // Custom message when locked
  final String? lockedMessage;

  const GameConfig({
    required this.gameId,
    required this.title,
    this.isActive = true,
    this.requiresLocation = true,
    this.frequency = GameFrequency.daily,
    this.activeWeekdays = const [],
    this.validFrom,
    this.validUntil,
    this.allowedUserLevels = const [], // Empty = all levels allowed
    this.lockedMessage,
  });

  // Factory for Firestore
  factory GameConfig.fromMap(Map<String, dynamic> map, String id) {
    return GameConfig(
      gameId: id,
      title: map['title'] ?? '',
      isActive: map['isActive'] ?? true,
      requiresLocation: map['requiresLocation'] ?? true,
      frequency: _parseFrequency(map['frequency']),
      activeWeekdays: List<int>.from(map['activeWeekdays'] ?? []),
      validFrom: (map['validFrom'] as Timestamp?)?.toDate(),
      validUntil: (map['validUntil'] as Timestamp?)?.toDate(),
      allowedUserLevels: List<String>.from(map['allowedUserLevels'] ?? []),
      lockedMessage: map['lockedMessage'],
    );
  }

  static GameFrequency _parseFrequency(String? value) {
    switch (value) {
      case 'weekly':
        return GameFrequency.weekly;
      case 'unlimited':
        return GameFrequency.unlimited;
      case 'oncePerStay':
        return GameFrequency.oncePerStay;
      case 'daily':
      default:
        return GameFrequency.daily;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isActive': isActive,
      'requiresLocation': requiresLocation,
      'frequency': frequency.name,
      'activeWeekdays': activeWeekdays,
      'validFrom': validFrom != null ? Timestamp.fromDate(validFrom!) : null,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
      'allowedUserLevels': allowedUserLevels,
      'lockedMessage': lockedMessage,
    };
  }
}
