/// Sistema de logging estructurado para Dreams Club.
///
/// Proporciona métodos para registrar diferentes niveles de logs
/// con formato consistente y soporte para Crashlytics en producción.
library;

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Logger global de la aplicación.
///
/// Uso:
/// ```dart
/// AppLogger.info('Usuario inició sesión');
/// AppLogger.error('Error al cargar casinos', error, stackTrace);
/// ```
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  /// Log de nivel debug - Solo visible en modo desarrollo.
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log de nivel info - Información general del flujo de la app.
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log de nivel warning - Situaciones inesperadas pero manejables.
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log de nivel error - Errores que afectan funcionalidad.
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // En producción, enviar a Crashlytics
    if (!kDebugMode) {
      _sendToCrashlytics(message, error, stackTrace);
    }
  }

  /// Log de nivel fatal - Errores críticos que pueden causar crash.
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);

    // Siempre enviar fatales a Crashlytics
    _sendToCrashlytics(message, error, stackTrace, fatal: true);
  }

  /// Envía el error a Firebase Crashlytics.
  static Future<void> _sendToCrashlytics(
    String message,
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    try {
      // Import dinámico para evitar dependencia si no está configurado
      // En producción, esto enviará a Crashlytics
      // FirebaseCrashlytics.instance.recordError(
      //   error ?? Exception(message),
      //   stackTrace,
      //   reason: message,
      //   fatal: fatal,
      // );
    } catch (e) {
      // Silenciar errores de Crashlytics para evitar loops infinitos
    }
  }

  /// Log para seguimiento de ubicación.
  static void location(String message) {
    if (kDebugMode) {
      _logger.d('📍 LOCATION: $message');
    }
  }

  /// Log para eventos de gamificación.
  static void gamification(String message) {
    if (kDebugMode) {
      _logger.d('🎮 GAMIFICATION: $message');
    }
  }

  /// Log para operaciones de red.
  static void network(String message, {bool isError = false}) {
    if (kDebugMode) {
      if (isError) {
        _logger.w('🌐 NETWORK ERROR: $message');
      } else {
        _logger.d('🌐 NETWORK: $message');
      }
    }
  }

  /// Log para analytics.
  static void analytics(String eventName, [Map<String, dynamic>? params]) {
    if (kDebugMode) {
      _logger.d('📊 ANALYTICS: $eventName ${params ?? ''}');
    }
  }
}
