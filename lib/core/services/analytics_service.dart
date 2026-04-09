/// Servicio de Analytics para tracking de eventos en Dreams Club.
///
/// Centraliza todos los eventos de analytics para facilitar
/// el seguimiento del comportamiento del usuario.
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Servicio para registrar eventos de analytics.
class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// Inicializa el servicio de Analytics.
  static Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      AppLogger.info('Analytics inicializado correctamente');
    } catch (e) {
      AppLogger.error('Error inicializando Analytics', e);
    }
  }

  /// Observer para tracking automático de navegación.
  static FirebaseAnalyticsObserver? get observer => _observer;

  // ============================================
  // EVENTOS DE USUARIO
  // ============================================

  /// Registra inicio de sesión.
  static Future<void> logLogin({String? method}) async {
    await _logEvent('login', {'method': method ?? 'default'});
  }

  /// Registra registro de usuario.
  static Future<void> logSignUp({String? method}) async {
    await _logEvent('sign_up', {'method': method ?? 'default'});
  }

  /// Establece el ID de usuario para tracking.
  static Future<void> setUserId(String userId) async {
    try {
      await _analytics?.setUserId(id: userId);
      AppLogger.analytics('setUserId', {'userId': userId});
    } catch (e) {
      AppLogger.error('Error setting user ID', e);
    }
  }

  /// Establece propiedades de usuario.
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics?.setUserProperty(name: name, value: value);
      AppLogger.analytics('setUserProperty', {'name': name, 'value': value});
    } catch (e) {
      AppLogger.error('Error setting user property', e);
    }
  }

  // ============================================
  // EVENTOS DE CASINO
  // ============================================

  /// Registra visita a un casino (detectada por GPS).
  static Future<void> logCasinoVisit({
    required String casinoId,
    required String casinoName,
  }) async {
    await _logEvent('casino_visit', {
      'casino_id': casinoId,
      'casino_name': casinoName,
      'detection_method': 'gps',
    });
  }

  /// Registra cuando el usuario ve los detalles de un casino.
  static Future<void> logCasinoDetailView({
    required String casinoId,
    required String casinoName,
  }) async {
    await _logEvent('view_casino_detail', {
      'casino_id': casinoId,
      'casino_name': casinoName,
    });
  }

  /// Registra cuando el usuario establece un casino como favorito.
  static Future<void> logSetFavoriteCasino({
    required String casinoId,
    required String casinoName,
  }) async {
    await _logEvent('set_favorite_casino', {
      'casino_id': casinoId,
      'casino_name': casinoName,
    });
  }

  // ============================================
  // EVENTOS DE GAMIFICACIÓN
  // ============================================

  /// Registra desbloqueo de logro.
  static Future<void> logAchievementUnlocked({
    required String achievementId,
    required String achievementName,
    required int pointsEarned,
  }) async {
    await _logEvent('unlock_achievement', {
      'achievement_id': achievementId,
      'achievement_name': achievementName,
      'points_earned': pointsEarned,
    });
  }

  /// Registra giro de slot machine.
  static Future<void> logSlotMachineSpin({
    required bool won,
    required int pointsWon,
    required String casinoId,
  }) async {
    await _logEvent('slot_machine_spin', {
      'won': won,
      'points_won': pointsWon,
      'casino_id': casinoId,
    });
  }

  /// Registra giro de ruleta.
  static Future<void> logSpinWheel({
    required String prizeType,
    required int pointsWon,
  }) async {
    await _logEvent('spin_wheel', {
      'prize_type': prizeType,
      'points_won': pointsWon,
    });
  }

  /// Registra reclamo de bono diario.
  static Future<void> logDailyBonus({
    required int pointsEarned,
    required int currentStreak,
  }) async {
    await _logEvent('claim_daily_bonus', {
      'points_earned': pointsEarned,
      'current_streak': currentStreak,
    });
  }

  // ============================================
  // EVENTOS DE CONTENIDO
  // ============================================

  /// Registra visualización de evento.
  static Future<void> logViewEvent({
    required String eventId,
    required String eventName,
  }) async {
    await _logEvent('view_event', {
      'event_id': eventId,
      'event_name': eventName,
    });
  }

  /// Registra visualización de promoción.
  static Future<void> logViewPromotion({
    required String promotionId,
    required String promotionName,
  }) async {
    await _logEvent('view_promotion', {
      'promotion_id': promotionId,
      'promotion_name': promotionName,
    });
  }

  /// Registra visualización de restaurante.
  static Future<void> logViewRestaurant({
    required String restaurantId,
    required String restaurantName,
  }) async {
    await _logEvent('view_restaurant', {
      'restaurant_id': restaurantId,
      'restaurant_name': restaurantName,
    });
  }

  // ============================================
  // EVENTOS DE INTERACCIÓN
  // ============================================

  /// Registra escaneo de QR.
  static Future<void> logQRScan({
    required String qrContent,
    required bool success,
  }) async {
    await _logEvent('qr_scan', {
      'qr_content_type': _categorizeQRContent(qrContent),
      'success': success,
    });
  }

  /// Registra compartir contenido.
  static Future<void> logShare({
    required String contentType,
    required String contentId,
  }) async {
    await _logEvent('share', {
      'content_type': contentType,
      'content_id': contentId,
    });
  }

  /// Registra uso del mapa.
  static Future<void> logOpenMap({
    required String casinoId,
    required String casinoName,
  }) async {
    await _logEvent('open_map', {
      'casino_id': casinoId,
      'casino_name': casinoName,
    });
  }

  // ============================================
  // EVENTOS DE CONFIGURACIÓN
  // ============================================

  /// Registra cambio en permisos de ubicación.
  static Future<void> logLocationPermissionChange({
    required String permissionLevel, // 'always', 'while_in_use', 'denied'
  }) async {
    await _logEvent('location_permission_change', {
      'permission_level': permissionLevel,
    });
  }

  /// Registra cambio en configuración de notificaciones.
  static Future<void> logNotificationSettingChange({
    required bool enabled,
  }) async {
    await _logEvent('notification_setting_change', {
      'enabled': enabled,
    });
  }

  // ============================================
  // MÉTODOS INTERNOS
  // ============================================

  static String _categorizeQRContent(String content) {
    if (content.startsWith('http')) return 'url';
    if (content.startsWith('dreams://')) return 'deep_link';
    return 'other';
  }

  static Future<void> _logEvent(
    String name,
    Map<String, Object> parameters,
  ) async {
    try {
      // Agregar timestamp
      parameters['timestamp'] = DateTime.now().toIso8601String();

      await _analytics?.logEvent(
        name: name,
        parameters: parameters,
      );

      AppLogger.analytics(name, parameters);
    } catch (e) {
      AppLogger.error('Error logging event: $name', e);
    }
  }
}
