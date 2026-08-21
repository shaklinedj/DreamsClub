import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuración visual de Prestigio y Tipografía según el Nivel de Racha del Usuario
class StreakPrestigeConfig {
  final int minStreak;
  final String titleText;
  final String badgeName;
  final TextStyle titleStyle;
  final List<Color> emblemGlowColors;
  final Color primaryAccent;
  final Color borderGlowColor;
  final String iconEmoji;

  const StreakPrestigeConfig({
    required this.minStreak,
    required this.titleText,
    required this.badgeName,
    required this.titleStyle,
    required this.emblemGlowColors,
    required this.primaryAccent,
    required this.borderGlowColor,
    required this.iconEmoji,
  });

  static StreakPrestigeConfig forStreak(int streak) {
    if (streak >= 30) {
      return StreakPrestigeConfig(
        minStreak: 30,
        titleText: '🔥 LEYENDA ABSOLUTA DREAMS 🔥',
        badgeName: '⚡ Racha 30d: Leyenda Absoluta Supremacía',
        titleStyle: GoogleFonts.unifrakturCook(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFD700),
          letterSpacing: 1.5,
          shadows: const [
            Shadow(color: Color(0xFFFF0055), blurRadius: 18),
            Shadow(color: Color(0xFFFFD700), blurRadius: 30),
          ],
        ),
        emblemGlowColors: const [Color(0xFFFF0055), Color(0xFFFFD700), Color(0xFF9945FF)],
        primaryAccent: const Color(0xFFFFD700),
        borderGlowColor: const Color(0xFFFF0055),
        iconEmoji: '🔥',
      );
    } else if (streak >= 14) {
      return StreakPrestigeConfig(
        minStreak: 14,
        titleText: '🔮 DREAMS PATAGÓNICO 🔮',
        badgeName: '🔮 Racha 14d: Gran Brujo Patagónico',
        titleStyle: GoogleFonts.pirataOne(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF00FF87),
          letterSpacing: 2.0,
          shadows: const [
            Shadow(color: Color(0xFF00FF87), blurRadius: 15),
            Shadow(color: Color(0xFF60EFFF), blurRadius: 25),
          ],
        ),
        emblemGlowColors: const [Color(0xFF00FF87), Color(0xFF60EFFF)],
        primaryAccent: const Color(0xFF00FF87),
        borderGlowColor: const Color(0xFF00FF87),
        iconEmoji: '💎',
      );
    } else if (streak >= 7) {
      return StreakPrestigeConfig(
        minStreak: 7,
        titleText: '👑 DREAMS CLUB VIP GOLD 👑',
        badgeName: '👑 Racha 7d: Maestro VIP Gold',
        titleStyle: GoogleFonts.cinzelDecorative(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFFD700),
          letterSpacing: 1.2,
          shadows: const [
            Shadow(color: Color(0xFFFFD700), blurRadius: 16),
            Shadow(color: Color(0xFFFFA500), blurRadius: 24),
          ],
        ),
        emblemGlowColors: const [Color(0xFFFFD700), Color(0xFFFFA500)],
        primaryAccent: const Color(0xFFFFD700),
        borderGlowColor: const Color(0xFFFFD700),
        iconEmoji: '👑',
      );
    } else if (streak >= 3) {
      return StreakPrestigeConfig(
        minStreak: 3,
        titleText: '⚔️ DREAMS COYHAIQUE ⚔️',
        badgeName: '🛡️ Racha 3d: Guerrero Coyhaique',
        titleStyle: GoogleFonts.unifrakturCook(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFE0E0E0),
          letterSpacing: 1.5,
          shadows: const [
            Shadow(color: Color(0xFF00F2FE), blurRadius: 14),
            Shadow(color: Color(0xFF4FACFE), blurRadius: 20),
          ],
        ),
        emblemGlowColors: const [Color(0xFF00F2FE), Color(0xFF4FACFE)],
        primaryAccent: const Color(0xFF00F2FE),
        borderGlowColor: const Color(0xFF00F2FE),
        iconEmoji: '🎉',
      );
    } else if (streak >= 1) {
      return StreakPrestigeConfig(
        minStreak: 1,
        titleText: '🏔️ DREAMS CLUB 🏔️',
        badgeName: '🏔️ Racha 1d: Aventurero Aysén',
        titleStyle: GoogleFonts.cinzel(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFCD7F32),
          letterSpacing: 1.0,
          shadows: const [
            Shadow(color: Color(0xFFCD7F32), blurRadius: 10),
          ],
        ),
        emblemGlowColors: const [Color(0xFFCD7F32), Color(0xFFD4AF37)],
        primaryAccent: const Color(0xFFCD7F32),
        borderGlowColor: const Color(0xFFCD7F32),
        iconEmoji: '🏔️',
      );
    } else {
      return StreakPrestigeConfig(
        minStreak: 0,
        titleText: 'DREAMS CLUB',
        badgeName: 'Explorador Dreams',
        titleStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.0,
        ),
        emblemGlowColors: const [Color(0xFF00F2FE)],
        primaryAccent: const Color(0xFF00F2FE),
        borderGlowColor: const Color(0xFF00F2FE),
        iconEmoji: '✨',
      );
    }
  }
}
