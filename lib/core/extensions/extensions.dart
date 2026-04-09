/// Extensiones útiles para tipos comunes.
///
/// Proporciona métodos convenience para String, DateTime, etc.
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extensiones para String.
extension StringExtensions on String {
  /// Capitaliza la primera letra.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitaliza cada palabra.
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Trunca el string a un máximo de caracteres.
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Verifica si es un email válido.
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Verifica si es una URL válida.
  bool get isValidUrl {
    return Uri.tryParse(this)?.hasAbsolutePath ?? false;
  }

  /// Convierte a nullable si está vacío.
  String? get nullIfEmpty => isEmpty ? null : this;
}

/// Extensiones para String nullable.
extension NullableStringExtensions on String? {
  /// Retorna true si es null o está vacío.
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Retorna true si no es null y no está vacío.
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// Retorna el string o un valor por defecto.
  String orDefault([String defaultValue = '']) => this ?? defaultValue;
}

/// Extensiones para DateTime.
extension DateTimeExtensions on DateTime {
  /// Formatea como fecha corta (dd/MM/yyyy).
  String get shortDate => DateFormat('dd/MM/yyyy').format(this);

  /// Formatea como fecha larga (dd de MMMM, yyyy).
  String get longDate => DateFormat('dd \'de\' MMMM, yyyy', 'es').format(this);

  /// Formatea como hora (HH:mm).
  String get time => DateFormat('HH:mm').format(this);

  /// Formatea como fecha y hora.
  String get dateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);

  /// Verifica si es hoy.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Verifica si es ayer.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Verifica si es mañana.
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Verifica si está en el pasado.
  bool get isPast => isBefore(DateTime.now());

  /// Verifica si está en el futuro.
  bool get isFuture => isAfter(DateTime.now());

  /// Retorna descripción relativa (hoy, ayer, mañana, o fecha).
  String get relativeDate {
    if (isToday) return 'Hoy';
    if (isYesterday) return 'Ayer';
    if (isTomorrow) return 'Mañana';
    return shortDate;
  }

  /// Inicio del día (00:00:00).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Fin del día (23:59:59).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
}

/// Extensiones para números.
extension NumExtensions on num {
  /// Formatea como precio CLP.
  String get asCLP => NumberFormat.currency(
        locale: 'es_CL',
        symbol: '\$',
        decimalDigits: 0,
      ).format(this);

  /// Formatea con separador de miles.
  String get formatted => NumberFormat('#,###', 'es').format(this);

  /// Formatea como porcentaje.
  String get asPercent => '${toStringAsFixed(1)}%';

  /// Formatea como puntos Dreams.
  String get asDreamsPoints => '$formatted pts';
}

/// Extensiones para List.
extension ListExtensions<T> on List<T> {
  /// Retorna el elemento en el índice o null si no existe.
  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }

  /// Retorna el primer elemento o null si está vacía.
  T? get firstOrNull => isEmpty ? null : first;

  /// Retorna el último elemento o null si está vacía.
  T? get lastOrNull => isEmpty ? null : last;

  /// Divide la lista en chunks de tamaño especificado.
  List<List<T>> chunked(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}

/// Extensiones para BuildContext.
extension BuildContextExtensions on BuildContext {
  /// Acceso rápido al tema.
  ThemeData get theme => Theme.of(this);

  /// Acceso rápido a los colores del tema.
  ColorScheme get colors => theme.colorScheme;

  /// Acceso rápido a los estilos de texto.
  TextTheme get textTheme => theme.textTheme;

  /// Acceso rápido al tamaño de pantalla.
  Size get screenSize => MediaQuery.of(this).size;

  /// Ancho de pantalla.
  double get screenWidth => screenSize.width;

  /// Alto de pantalla.
  double get screenHeight => screenSize.height;

  /// Verifica si es pantalla pequeña (< 600px).
  bool get isSmallScreen => screenWidth < 600;

  /// Verifica si es tablet (>= 600px && < 900px).
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;

  /// Verifica si es pantalla grande (>= 900px).
  bool get isLargeScreen => screenWidth >= 900;

  /// Padding seguro (notch, etc).
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Muestra un SnackBar.
  void showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Muestra un SnackBar de error.
  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Muestra un SnackBar de éxito.
  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Extensiones para Color.
extension ColorExtensions on Color {
  /// Aclara el color por un factor (0.0 - 1.0).
  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Oscurece el color por un factor (0.0 - 1.0).
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Convierte a string hexadecimal.
  String get toHex {
    // Usar la nueva API de Color donde r/g/b están en rango 0-255
    final rHex = r.toInt().toRadixString(16).padLeft(2, '0');
    final gHex = g.toInt().toRadixString(16).padLeft(2, '0');
    final bHex = b.toInt().toRadixString(16).padLeft(2, '0');
    return '#$rHex$gHex$bHex';
  }
}
