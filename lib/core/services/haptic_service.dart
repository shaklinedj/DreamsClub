/// Servicio de feedback háptico para interacciones premium.
///
/// Proporciona vibración táctil para mejorar la experiencia
/// del usuario en acciones importantes.
library;

import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Tipo de feedback háptico.
enum HapticFeedbackType {
  /// Feedback ligero para toques simples.
  light,

  /// Feedback medio para acciones normales.
  medium,

  /// Feedback fuerte para acciones importantes.
  heavy,

  /// Feedback de éxito (gano premio, logro desbloqueado).
  success,

  /// Feedback de error.
  error,

  /// Feedback de advertencia.
  warning,

  /// Feedback de selección.
  selection,
}

/// Servicio para proporcionar feedback háptico.
class HapticService {
  HapticService._();

  static bool? _hasVibrator;
  static bool? _hasAmplitudeControl;

  /// Inicializa el servicio verificando capacidades del dispositivo.
  static Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();
      _hasAmplitudeControl = await Vibration.hasAmplitudeControl();
      AppLogger.debug(
        'HapticService: vibrator=$_hasVibrator, amplitude=$_hasAmplitudeControl',
      );
    } catch (e) {
      _hasVibrator = false;
      _hasAmplitudeControl = false;
      AppLogger.warning('No se pudo inicializar HapticService', e);
    }
  }

  /// Ejecuta feedback háptico del tipo especificado.
  static Future<void> feedback(HapticFeedbackType type) async {
    try {
      switch (type) {
        case HapticFeedbackType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticFeedbackType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticFeedbackType.success:
          await _successPattern();
          break;
        case HapticFeedbackType.error:
          await _errorPattern();
          break;
        case HapticFeedbackType.warning:
          await HapticFeedback.mediumImpact();
          break;
        case HapticFeedbackType.selection:
          await HapticFeedback.selectionClick();
          break;
      }
    } catch (e) {
      // Silenciar errores de vibración
    }
  }

  /// Patrón de vibración para éxito.
  static Future<void> _successPattern() async {
    if (_hasVibrator != true) {
      await HapticFeedback.mediumImpact();
      return;
    }

    if (_hasAmplitudeControl == true) {
      // Patrón suave ascendente
      await Vibration.vibrate(
          pattern: [0, 50, 50, 100], intensities: [0, 100, 0, 200]);
    } else {
      // Fallback simple
      await Vibration.vibrate(duration: 100);
    }
  }

  /// Patrón de vibración para error.
  static Future<void> _errorPattern() async {
    if (_hasVibrator != true) {
      await HapticFeedback.heavyImpact();
      return;
    }

    if (_hasAmplitudeControl == true) {
      // Patrón corto y fuerte
      await Vibration.vibrate(
          pattern: [0, 100, 50, 100], intensities: [0, 255, 0, 255]);
    } else {
      await Vibration.vibrate(duration: 200);
    }
  }

  // ============================================
  // MÉTODOS CONVENIENCE
  // ============================================

  /// Feedback para tap en botón.
  static Future<void> buttonTap() => feedback(HapticFeedbackType.light);

  /// Feedback para selección de item.
  static Future<void> select() => feedback(HapticFeedbackType.selection);

  /// Feedback para acción completada con éxito.
  static Future<void> success() => feedback(HapticFeedbackType.success);

  /// Feedback para error.
  static Future<void> error() => feedback(HapticFeedbackType.error);

  /// Feedback para slot machine spin.
  static Future<void> slotSpin() async {
    if (_hasVibrator != true) return;

    // Vibración continua durante el spin
    await Vibration.vibrate(duration: 50);
  }

  /// Feedback para ganar premio.
  static Future<void> prizeWon() async {
    if (_hasVibrator != true) {
      await HapticFeedback.heavyImpact();
      return;
    }

    // Patrón celebración
    await Vibration.vibrate(
      pattern: [0, 100, 100, 100, 100, 200],
      intensities: [0, 150, 0, 200, 0, 255],
    );
  }

  /// Feedback para logro desbloqueado.
  static Future<void> achievementUnlocked() async => prizeWon();

  /// Feedback para pull-to-refresh.
  static Future<void> refresh() => feedback(HapticFeedbackType.medium);

  /// Feedback para navegación.
  static Future<void> navigate() => feedback(HapticFeedbackType.light);

  /// Feedback para toggle switch.
  static Future<void> toggle() => feedback(HapticFeedbackType.selection);
}
