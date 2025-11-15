import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData themeData = ThemeData(
    primaryColor: const Color(0xFFD4AF37),
    scaffoldBackgroundColor: const Color(0xFF1a1a1a),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD4AF37),
      secondary: Color(0xFFD4AF37),
      surface: Color(0xFF2a2a2a),
      onPrimary: Color(0xFF1a1a1a),
      onSecondary: Color(0xFF1a1a1a),
      onSurface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1a1a1a),
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFFD4AF37)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2a2a2a),
      selectedItemColor: Color(0xFFD4AF37),
      unselectedItemColor: Colors.grey,
    ),
  );
}
