/// Rate limiter para prevenir operaciones excesivas.
///
/// Útil para limitar llamadas a APIs, actualizaciones de UI,
/// y otras operaciones que pueden ser costosas si se ejecutan muy seguido.
library;

import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Limita la frecuencia de ejecución de operaciones.
///
/// Ejemplo:
/// ```dart
/// final limiter = RateLimiter();
///
/// await limiter.execute(
///   key: 'refresh_casinos',
///   operation: () => casinoService.getAllCasinos(),
///   minInterval: Duration(minutes: 5),
/// );
/// ```
class RateLimiter {
  final Map<String, DateTime> _lastExecutionTimes = {};

  /// Ejecuta una operación si ha pasado el intervalo mínimo desde la última ejecución.
  ///
  /// Retorna `null` si la operación fue bloqueada por rate limiting.
  Future<T?> execute<T>({
    required String key,
    required Future<T> Function() operation,
    required Duration minInterval,
  }) async {
    final lastExecution = _lastExecutionTimes[key];
    final now = DateTime.now();

    if (lastExecution != null) {
      final timeSinceLastExecution = now.difference(lastExecution);
      if (timeSinceLastExecution < minInterval) {
        final remaining = minInterval - timeSinceLastExecution;
        AppLogger.debug(
          'Rate limit: $key bloqueado. Próxima ejecución en ${remaining.inSeconds}s',
        );
        return null;
      }
    }

    _lastExecutionTimes[key] = now;
    return await operation();
  }

  /// Ejecuta una operación forzando la ejecución (ignora rate limit).
  Future<T> forceExecute<T>({
    required String key,
    required Future<T> Function() operation,
  }) async {
    _lastExecutionTimes[key] = DateTime.now();
    return await operation();
  }

  /// Verifica si una operación puede ejecutarse sin bloqueo.
  bool canExecute(String key, Duration minInterval) {
    final lastExecution = _lastExecutionTimes[key];
    if (lastExecution == null) return true;

    final timeSinceLastExecution = DateTime.now().difference(lastExecution);
    return timeSinceLastExecution >= minInterval;
  }

  /// Resetea el rate limit para una key específica.
  void reset(String key) {
    _lastExecutionTimes.remove(key);
  }

  /// Limpia todos los rate limits.
  void clear() {
    _lastExecutionTimes.clear();
  }

  /// Retorna el tiempo restante hasta que se pueda ejecutar una operación.
  Duration? timeUntilNextExecution(String key, Duration minInterval) {
    final lastExecution = _lastExecutionTimes[key];
    if (lastExecution == null) return null;

    final timeSinceLastExecution = DateTime.now().difference(lastExecution);
    if (timeSinceLastExecution >= minInterval) return null;

    return minInterval - timeSinceLastExecution;
  }
}

/// Instancia global del rate limiter para uso en toda la app.
final globalRateLimiter = RateLimiter();
