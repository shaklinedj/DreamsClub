/// Constantes globales de la aplicación Dreams Club.
///
/// Centraliza todos los valores mágicos para facilitar el mantenimiento
/// y asegurar consistencia en toda la app.
library;

import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // ============================================
  // LOCATION
  // ============================================

  /// Radio de proximidad en metros para detectar que el usuario está en un casino.
  static const double casinoProximityMeters = 500.0;

  /// Distancia mínima en metros para actualizar la ubicación.
  static const double locationUpdateDistanceMeters = 100.0;

  /// Precisión de ubicación para monitoreo en segundo plano.
  /// Usa 'balanced' para reducir consumo de batería.
  static const double locationBalancedAccuracyMeters = 100.0;

  // ============================================
  // UI DIMENSIONS
  // ============================================

  /// Altura de la barra de navegación inferior.
  static const double navBarHeight = 60.0;

  /// Tamaño del botón flotante central (FAB).
  static const double fabSize = 70.0;

  /// Radio de borde estándar para cards.
  static const double cardBorderRadius = 16.0;

  /// Radio de borde para botones.
  static const double buttonBorderRadius = 12.0;

  /// Padding horizontal estándar.
  static const double horizontalPadding = 16.0;

  /// Padding vertical estándar.
  static const double verticalPadding = 12.0;

  // ============================================
  // ANIMATIONS
  // ============================================

  /// Duración estándar para animaciones.
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Duración para animaciones rápidas.
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Duración para animaciones lentas.
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Duración del splash screen.
  static const Duration splashDuration = Duration(seconds: 3);

  // ============================================
  // GAMIFICATION
  // ============================================

  /// Puntos otorgados por bono diario.
  static const int dailyBonusPoints = 50;

  /// Puntos bonus por mantener racha de visitas.
  static const int streakBonusPoints = 100;

  /// Días para considerar una racha activa.
  static const int streakDaysThreshold = 7;

  /// Puntos por visitar un casino nuevo.
  static const int newCasinoVisitPoints = 200;

  // ============================================
  // NETWORK
  // ============================================

  /// Tiempo máximo de espera para requests HTTP.
  static const Duration httpTimeout = Duration(seconds: 30);

  /// Número máximo de reintentos para operaciones de red.
  static const int maxRetryAttempts = 3;

  /// Delay base entre reintentos (se multiplica exponencialmente).
  static const Duration retryBaseDelay = Duration(seconds: 2);

  // ============================================
  // CACHE
  // ============================================

  /// Tiempo máximo que los datos permanecen en caché.
  static const Duration cacheMaxAge = Duration(hours: 24);

  /// Ancho máximo para imágenes en caché de memoria.
  static const int imageCacheMaxWidth = 800;

  /// Ancho máximo para imágenes en caché de disco.
  static const int imageDiskCacheMaxWidth = 1000;

  /// Tamaño máximo total del caché de video (disco) para el feed.
  /// límite ayuda a evitar crecimiento indefinido.
  static const int feedVideoCacheMaxSizeBytes = 1024 * 1024 * 1024; // 1GB

  /// Tamaño máximo por archivo/stream cacheado (disco) para el feed.
  static const int feedVideoCacheMaxFileSizeBytes = 400 * 1024 * 1024; // 400MB

  /// Cantidad objetivo a precachear antes de reproducir (disco).
  static const int feedVideoPreCacheSizeBytes = 20 * 1024 * 1024; // 20MB

  // ============================================
  // RATE LIMITING
  // ============================================

  /// Intervalo mínimo entre actualizaciones de casinos.
  static const Duration refreshCasinosInterval = Duration(minutes: 5);

  /// Intervalo mínimo entre actualizaciones de eventos.
  static const Duration refreshEventsInterval = Duration(minutes: 10);

  // ============================================
  // NOTIFICATIONS
  // ============================================

  /// ID del canal de notificaciones para el servicio en segundo plano.
  static const String backgroundNotificationChannelId = 'my_foreground';

  /// Nombre del canal de notificaciones.
  static const String backgroundNotificationChannelName =
      'Dreams Club Background Service';

  /// ID de la notificación del servicio en primer plano.
  static const int foregroundNotificationId = 888;

  // ============================================
  // SHARED PREFERENCES KEYS
  // ============================================

  static const String prefKeyFavoriteCasino = 'favorite_casino_id';
  static const String prefKeyLocationTrackingEnabled =
      'location_tracking_enabled';
  static const String prefKeyNotificationsEnabled = 'notifications_enabled';
  static const String prefKeyLastDailyBonus = 'last_daily_bonus_date';
  static const String prefKeyStreak = 'current_streak';
  static const String prefKeyTotalPoints = 'total_points';
  static const String prefKeyFirstLaunch = 'is_first_launch';
  static const String prefKeyLocationUpgradeDismissed =
      'location_upgrade_dismissed';
  static const String prefKeyBackgroundCasinosData = 'background_casinos_data';

  // ============================================
  // COLORS (para acceso rápido fuera del theme)
  // ============================================

  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFA67C00);
  static const Color backgroundColor = Color(0xFF0D0D0D);
  static const Color surfaceColor = Color(0xFF141414);

  // Ya no usamos Drive API keys aquí porque leemos de Firestore
}
