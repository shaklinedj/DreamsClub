/// Enums para tipos de notificación.
///
/// Proporciona type-safety en lugar de usar strings mágicos.
library;

/// Tipos de notificación en la app.
enum NotificationType {
  achievement('achievement', 'Logro', '🏆'),
  visit('visit', 'Visita', '📍'),
  promotion('promotion', 'Promoción', '🎁'),
  event('event', 'Evento', '🎉'),
  dailyBonus('daily_bonus', 'Bono Diario', '💰'),
  dreamsMania('dreams_mania', 'Dreams Mania', '🎰'),
  system('system', 'Sistema', '⚙️');

  const NotificationType(this.id, this.displayName, this.emoji);

  final String id;
  final String displayName;
  final String emoji;

  /// Crea un NotificationType desde un string id.
  static NotificationType fromId(String id) {
    return NotificationType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => NotificationType.system,
    );
  }
}

/// Estados de permiso de ubicación.
enum LocationPermissionState {
  notDetermined('not_determined', 'No determinado'),
  denied('denied', 'Denegado'),
  deniedForever('denied_forever', 'Denegado permanentemente'),
  whileInUse('while_in_use', 'Mientras se usa'),
  always('always', 'Siempre');

  const LocationPermissionState(this.id, this.displayName);

  final String id;
  final String displayName;

  bool get isGranted => this == whileInUse || this == always;
  bool get isAlways => this == always;
}

/// Niveles de usuario en el programa de lealtad.
enum UserLevel {
  bronze('bronze', 'Bronce', 0),
  silver('silver', 'Plata', 1000),
  gold('gold', 'Oro', 5000),
  platinum('platinum', 'Platino', 15000),
  diamond('diamond', 'Diamante', 50000),
  black('black', 'Black', 100000);

  const UserLevel(this.id, this.displayName, this.minPoints);

  final String id;
  final String displayName;
  final int minPoints;

  /// Obtiene el nivel basado en los puntos.
  static UserLevel fromPoints(int points) {
    final levels = UserLevel.values.reversed.toList();
    for (final level in levels) {
      if (points >= level.minPoints) {
        return level;
      }
    }
    return UserLevel.bronze;
  }
}

/// Tipos de transacción de puntos.
enum TransactionType {
  earn('earn', 'Ganado'),
  redeem('redeem', 'Canjeado'),
  bonus('bonus', 'Bonus'),
  expired('expired', 'Expirado'),
  adjustment('adjustment', 'Ajuste');

  const TransactionType(this.id, this.displayName);

  final String id;
  final String displayName;

  bool get isPositive => this == earn || this == bonus;
}

/// Estados de un premio.
enum PrizeStatus {
  available('available', 'Disponible'),
  claimed('claimed', 'Reclamado'),
  redeemed('redeemed', 'Canjeado'),
  expired('expired', 'Expirado');

  const PrizeStatus(this.id, this.displayName);

  final String id;
  final String displayName;
}

/// Tipos de contenido para compartir.
enum ShareContentType {
  event('event'),
  promotion('promotion'),
  casino('casino'),
  achievement('achievement'),
  prize('prize');

  const ShareContentType(this.id);

  final String id;
}
