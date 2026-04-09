/// Helper para reintentar operaciones que pueden fallar.
///
/// Implementa lógica de retry con exponential backoff
/// para mejorar la resiliencia ante fallos de red.
library;

import 'dart:async';
import 'package:casinoloyalty_flutter/core/constants/app_constants.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Ejecuta una operación con reintentos automáticos.
///
/// Ejemplo:
/// ```dart
/// final casinos = await retryOperation(
///   operation: () => casinoService.getAllCasinos(),
///   operationName: 'getAllCasinos',
/// );
/// ```
Future<T> retryOperation<T>({
  required Future<T> Function() operation,
  String operationName = 'operation',
  int maxAttempts = AppConstants.maxRetryAttempts,
  Duration baseDelay = AppConstants.retryBaseDelay,
}) async {
  int attempts = 0;
  dynamic lastError;
  StackTrace? lastStackTrace;

  while (attempts < maxAttempts) {
    try {
      return await operation();
    } catch (e, stackTrace) {
      attempts++;
      lastError = e;
      lastStackTrace = stackTrace;

      AppLogger.warning(
        '$operationName falló (intento $attempts/$maxAttempts): $e',
      );

      if (attempts >= maxAttempts) {
        break;
      }

      // Exponential backoff: 2s, 4s, 8s...
      final delay = baseDelay * (1 << (attempts - 1));
      AppLogger.debug('Reintentando en ${delay.inSeconds}s...');
      await Future.delayed(delay);
    }
  }

  AppLogger.error(
    '$operationName falló después de $maxAttempts intentos',
    lastError,
    lastStackTrace,
  );

  throw lastError;
}

/// Ejecuta una operación con timeout.
///
/// Ejemplo:
/// ```dart
/// final result = await withTimeout(
///   operation: () => heavyOperation(),
///   timeout: Duration(seconds: 10),
/// );
/// ```
Future<T> withTimeout<T>({
  required Future<T> Function() operation,
  Duration timeout = AppConstants.httpTimeout,
  String operationName = 'operation',
}) async {
  try {
    return await operation().timeout(timeout);
  } on TimeoutException {
    AppLogger.warning(
        '$operationName excedió timeout de ${timeout.inSeconds}s');
    rethrow;
  }
}

/// Combina retry con timeout.
Future<T> retryWithTimeout<T>({
  required Future<T> Function() operation,
  String operationName = 'operation',
  int maxAttempts = AppConstants.maxRetryAttempts,
  Duration timeout = AppConstants.httpTimeout,
}) async {
  return retryOperation(
    operation: () => withTimeout(
      operation: operation,
      timeout: timeout,
      operationName: operationName,
    ),
    operationName: operationName,
    maxAttempts: maxAttempts,
  );
}
