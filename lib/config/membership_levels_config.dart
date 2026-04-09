import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:flutter/material.dart';

class MembershipLevelInfo {
  final UserLevel level;
  final int minPoints;
  final String description;
  final List<MembershipBenefit> benefits;
  final List<Color> gradientColors;

  const MembershipLevelInfo({
    required this.level,
    required this.minPoints,
    required this.description,
    required this.benefits,
    required this.gradientColors,
  });

  String get pointsRequirement =>
      '${minPoints.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} puntos';
}

class MembershipBenefit {
  final IconData icon;
  final String title;
  final String detail;

  const MembershipBenefit({
    required this.icon,
    required this.title,
    required this.detail,
  });
}

class MembershipLevelsConfig {
  static const List<MembershipLevelInfo> levels = [
    MembershipLevelInfo(
      level: UserLevel.blue,
      minPoints: 0,
      description: 'Nivel inicial con acceso a beneficios básicos del club.',
      gradientColors: [Color(0xFF1E88E5), Color(0xFF64B5F6)], // Azul vibrante
      benefits: [
        MembershipBenefit(
          icon: Icons.card_membership,
          title: 'Membresía Digital',
          detail: 'Acceso a la app y tarjeta digital',
        ),
        MembershipBenefit(
          icon: Icons.stars,
          title: 'Acumulación de Puntos',
          detail: 'Gana puntos por cada visita y juego',
        ),
      ],
    ),
    MembershipLevelInfo(
      level: UserLevel.gold,
      minPoints: 15000,
      description: 'Beneficios exclusivos y descuentos preferenciales.',
      gradientColors: [Color(0xFFFFA000), Color(0xFFFFC107)], // Dorado/Naranja
      benefits: [
        MembershipBenefit(
          icon: Icons.discount,
          title: 'Descuento',
          detail: '10% + Promo de 5% en Lucky 7',
        ),
        MembershipBenefit(
          icon: Icons.local_parking,
          title: 'Estacionamiento',
          detail: 'Gratuito',
        ),
        MembershipBenefit(
          icon: Icons.cake,
          title: 'Regalo de Cumpleaños',
          detail: '20.000 Promocionales',
        ),
        MembershipBenefit(
          icon: Icons.hotel,
          title: 'Tarifas Hoteles Dreams',
          detail:
              'Alta \$105.000* - Baja \$94.500*\nMonticello: Todo el año \$63.808*',
        ),
        MembershipBenefit(
          icon: Icons.swap_horiz,
          title: 'Canje Puntos',
          detail:
              '1 crédito juego canje = 1 punto (>10 pts)\nNoche Dreams: 60.000 pts\nMonticello: 20.000 pts',
        ),
      ],
    ),
    MembershipLevelInfo(
      level: UserLevel.black,
      minPoints: 75000,
      description: 'Nivel superior con trato VIP y mayores descuentos.',
      gradientColors: [Color(0xFF212121), Color(0xFF424242)], // Negro/Gris
      benefits: [
        MembershipBenefit(
          icon: Icons.discount,
          title: 'Descuento',
          detail: '15% + Promo de 5% en Lucky 7',
        ),
        MembershipBenefit(
          icon: Icons.local_parking,
          title: 'Estacionamiento',
          detail: 'Gratuito',
        ),
        MembershipBenefit(
          icon: Icons.cake,
          title: 'Regalo de Cumpleaños',
          detail: 'Noche de hotel + 40.000 Promocionales',
        ),
        MembershipBenefit(
          icon: Icons.hotel,
          title: 'Tarifas Hoteles Dreams',
          detail:
              'Alta \$94.500* - Baja \$87.150*\nMonticello: Todo el año \$63.808*',
        ),
        MembershipBenefit(
          icon: Icons.swap_horiz,
          title: 'Canje Puntos',
          detail:
              '1 crédito juego canje = 1 punto (>10 pts)\nNoche Dreams: 60.000 pts\nMonticello: 20.000 pts',
        ),
      ],
    ),
    MembershipLevelInfo(
      level: UserLevel.platinum,
      minPoints: 150000,
      description: 'La máxima exclusividad y beneficios sin límites.',
      gradientColors: [
        Color(0xFFB0BEC5),
        Color(0xFFE0E0E0)
      ], // Platino/Plateado
      benefits: [
        MembershipBenefit(
          icon: Icons.discount,
          title: 'Descuento',
          detail: '20% + Promo de 5% en Lucky 7',
        ),
        MembershipBenefit(
          icon: Icons.local_parking,
          title: 'Estacionamiento',
          detail: 'Gratuito',
        ),
        MembershipBenefit(
          icon: Icons.cake,
          title: 'Regalo de Cumpleaños',
          detail:
              'Noche de hotel.\nPromocionales: 50.000 + 50.000 Extra por oferta.',
        ),
        MembershipBenefit(
          icon: Icons.hotel,
          title: 'Tarifas Hoteles Dreams',
          detail:
              'Alta \$89.250* - Baja \$81.900*\nMonticello: Todo el año \$61.649*',
        ),
        MembershipBenefit(
          icon: Icons.swap_horiz,
          title: 'Canje Puntos',
          detail:
              '1 crédito juego canje = 1 punto (>10 pts)\nNoche Dreams: 60.000 pts\nMonticello: 20.000 pts',
        ),
      ],
    ),
  ];

  static MembershipLevelInfo getLevelInfo(UserLevel level) {
    return levels.firstWhere((info) => info.level == level,
        orElse: () => levels.first);
  }

  static MembershipLevelInfo? getNextLevel(UserLevel currentLevel) {
    final currentIndex =
        levels.indexWhere((info) => info.level == currentLevel);
    if (currentIndex != -1 && currentIndex < levels.length - 1) {
      return levels[currentIndex + 1];
    }
    return null; // Max level reached
  }
}
