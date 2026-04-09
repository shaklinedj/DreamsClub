import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colores Copec Style ---
  static const Color kPrimaryBlue = Color(0xFF0052CC); // Azul Principal
  static const Color kPrimaryDark = Color(0xFF003380); // Azul Oscuro
  static const Color kAccentRed = Color(0xFFE63946); // Acento (opcional)

  static const Color kBackground = Color(0xFFF4F6F8); // Gris muy claro (Fondo)
  static const Color kSurface = Color(0xFFFFFFFF); // Blanco (Tarjetas)

  static const Color kTextPrimary = Color(0xFF1A1A1A); // Negro suave
  static const Color kTextSecondary = Color(0xFF757575); // Gris texto

  // Gradiente Azul (opcional para botones o headers)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [kPrimaryBlue, kPrimaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient backgroundGradient(ColorScheme colorScheme) {
    return LinearGradient(
      colors: [
        colorScheme.surface,
        colorScheme.primary.withValues(alpha: 0.08),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  // --- Tipograf�a (Limpia y Moderna) ---
  static final TextTheme _appTextTheme = TextTheme(
    displayLarge: GoogleFonts.roboto(
        fontSize: 32, fontWeight: FontWeight.bold, color: kTextPrimary),
    displayMedium: GoogleFonts.roboto(
        fontSize: 28, fontWeight: FontWeight.bold, color: kTextPrimary),
    headlineMedium: GoogleFonts.roboto(
        fontSize: 24, fontWeight: FontWeight.w600, color: kTextPrimary),
    titleLarge: GoogleFonts.roboto(
        fontSize: 20, fontWeight: FontWeight.w600, color: kTextPrimary),
    titleMedium: GoogleFonts.roboto(
        fontSize: 16, fontWeight: FontWeight.w600, color: kTextPrimary),
    bodyLarge: GoogleFonts.openSans(
        fontSize: 16, fontWeight: FontWeight.normal, color: kTextPrimary),
    bodyMedium: GoogleFonts.openSans(
        fontSize: 14, fontWeight: FontWeight.normal, color: kTextSecondary),
    labelLarge: GoogleFonts.roboto(
        fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
  );

  // --- Tema Claro (Principal) ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: kPrimaryBlue,
    scaffoldBackgroundColor: kBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryBlue,
      primary: kPrimaryBlue,
      secondary: kPrimaryDark,
      surface: kSurface,
      onPrimary: Colors.white,
      onSurface: kTextPrimary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kSurface,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: kPrimaryBlue),
      titleTextStyle: _appTextTheme.titleLarge?.copyWith(color: kPrimaryBlue),
    ),
    textTheme: _appTextTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _appTextTheme.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryBlue, width: 2),
      ),
      labelStyle: const TextStyle(color: kTextSecondary),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: kSurface,
      selectedItemColor: kPrimaryBlue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: kPrimaryBlue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimaryBlue,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
    ),
    textTheme: _appTextTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}
