/// Servicio de Crashlytics para reporting de errores.
///
/// Integra Firebase Crashlytics para capturar y reportar
/// errores y crashes de la aplicación.
library;

import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Servicio para manejo de crashes y errores.
class CrashlyticsService {
  CrashlyticsService._();

  static FirebaseCrashlytics? _crashlytics;

  /// Inicializa Crashlytics y configura handlers de errores.
  static Future<void> initialize() async {
    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Desactivar en modo debug
      await _crashlytics?.setCrashlyticsCollectionEnabled(!kDebugMode);

      if (!kDebugMode) {
        // Capturar errores de Flutter
        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          _crashlytics?.recordFlutterFatalError(details);
        };

        // Capturar errores asíncronos
        PlatformDispatcher.instance.onError = (error, stack) {
          _crashlytics?.recordError(error, stack, fatal: true);
          return true;
        };
      }

      AppLogger.info('Crashlytics inicializado correctamente');
    } catch (e) {
      AppLogger.error('Error inicializando Crashlytics', e);
    }
  }

  /// Registra un error no fatal.
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Iterable<Object>? information,
  }) async {
    if (kDebugMode) {
      AppLogger.error(
        reason ?? 'Error registrado',
        exception,
        stack,
      );
      return;
    }

    try {
      await _crashlytics?.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
        information: information ?? [],
      );
    } catch (e) {
      // Silenciar errores de crashlytics para evitar loops
    }
  }

  /// Registra un mensaje de log personalizado.
  static Future<void> log(String message) async {
    try {
      await _crashlytics?.log(message);
      AppLogger.debug('Crashlytics log: $message');
    } catch (e) {
      // Silenciar
    }
  }

  /// Establece el ID de usuario para correlacionar crashes.
  static Future<void> setUserId(String userId) async {
    try {
      await _crashlytics?.setUserIdentifier(userId);
    } catch (e) {
      AppLogger.error('Error setting Crashlytics user ID', e);
    }
  }

  /// Establece una clave-valor personalizada.
  static Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics?.setCustomKey(key, value);
    } catch (e) {
      // Silenciar
    }
  }

  /// Fuerza un crash (solo para testing).
  static void forceCrash() {
    if (kDebugMode) {
      AppLogger.warning('⚠️ Force crash solo funciona en release mode');
      return;
    }
    _crashlytics?.crash();
  }

  /// Registra información del contexto actual.
  static Future<void> setContext({
    String? screen,
    String? action,
    Map<String, dynamic>? extra,
  }) async {
    if (screen != null) await setCustomKey('current_screen', screen);
    if (action != null) await setCustomKey('last_action', action);
    if (extra != null) {
      for (final entry in extra.entries) {
        await setCustomKey(entry.key, entry.value.toString());
      }
    }
  }
}

/// Tipo para errores con contexto adicional.
class AppError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  @override
  String toString() => 'AppError[$code]: $message';

  /// Reporta este error a Crashlytics.
  Future<void> report({bool fatal = false}) async {
    await CrashlyticsService.recordError(
      originalError ?? this,
      stackTrace,
      reason: message,
      fatal: fatal,
      information: context?.entries.map((e) => '${e.key}: ${e.value}'),
    );
  }
}
