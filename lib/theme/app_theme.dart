import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores principal (dorado)
  static const Color _primaryColor = Color(0xFFD4AF37); // Un dorado más clásico
  static const Color _primaryVariantColor = Color(0xFFAA8A2C);
  static const Color _secondaryColor = Color(0xFF4C4C4C);

  // Definición de TextTheme con Google Fonts
  static final TextTheme _appTextTheme = TextTheme(
    displayLarge: GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
    displayMedium: GoogleFonts.oswald(fontSize: 45, fontWeight: FontWeight.w400),
    displaySmall: GoogleFonts.oswald(fontSize: 36, fontWeight: FontWeight.w400),
    headlineLarge: GoogleFonts.roboto(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: GoogleFonts.roboto(fontSize: 28, fontWeight: FontWeight.w500),
    headlineSmall: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w500),
    titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
    titleSmall: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    bodyLarge: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    bodyMedium: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
    labelLarge: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25),
    labelMedium: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    labelSmall: GoogleFonts.openSans(fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5),
  );

  // Tema Claro
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
      primary: _primaryColor,
      onPrimary: Colors.black,
      secondary: _secondaryColor,
      surface: const Color(0xFFF5F5F5), // Un blanco ligeramente grisáceo
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: _appTextTheme.headlineSmall?.copyWith(color: _primaryColor),
    ),
    textTheme: _appTextTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: _appTextTheme.labelLarge,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  // Tema Oscuro
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
      primary: _primaryVariantColor,
      onPrimary: Colors.white,
      secondary: _secondaryColor,
      surface: const Color(0xFF212121), // Un gris oscuro para superficies
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: _primaryColor),
      titleTextStyle: _appTextTheme.headlineSmall?.copyWith(color: _primaryColor),
    ),
    textTheme: _appTextTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryVariantColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: _appTextTheme.labelLarge,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 6,
      color: Color(0xFF212121),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );
}
