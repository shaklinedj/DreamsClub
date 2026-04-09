import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/services/notification_service.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

/// Servicio para programar y disparar notificaciones reales
class RealNotificationService {
  static Timer? _dailyBonusTimer;
  static Timer? _dreamManiaTimer;
  static Timer? _proximityCheckTimer;

  /// Inicializar todas las notificaciones programadas
  static Future<void> initialize(Ref ref) async {
    // Cancelar timers existentes
    cancelAll();

    final user = ref.read(userProvider);

    // Notificación de bono diario (cada 24 horas)
    _scheduleDailyBonusNotification();

    // Notificación de Dreams Mania (cada 6 horas)
    _scheduleDreamsManiaNotification();

    // Notificación de cumpleaños si es hoy
    if (user.birthday != null) {
      _checkBirthdayNotification(user.name, user.birthday!);
    }

    // Notificación de bienvenida solo la primera vez
    await _showWelcomeNotificationOnce(user.name, user.levelName);
  }

  /// Programar notificación de bono diario
  static void _scheduleDailyBonusNotification() {
    // Disparar cada 24 horas
    _dailyBonusTimer = Timer.periodic(
      const Duration(hours: 24),
      (timer) async {
        await NotificationService.showNotification(
          id: 1001,
          title: '🎁 ¡Bono Diario Disponible!',
          body: 'No olvides reclamar tu bono diario. ¡Gana hasta 1000 puntos!',
          payload: 'daily_bonus',
        );
      },
    );

    // Disparar la primera notificación después de 1 hora
    Timer(const Duration(hours: 1), () async {
      await NotificationService.showNotification(
        id: 1001,
        title: '🎁 ¡Bono Diario Disponible!',
        body: 'No olvides reclamar tu bono diario. ¡Gana hasta 1000 puntos!',
        payload: 'daily_bonus',
      );
    });
  }

  /// Programar notificación de Dreams Mania
  static void _scheduleDreamsManiaNotification() {
    // Disparar cada 6 horas
    _dreamManiaTimer = Timer.periodic(
      const Duration(hours: 6),
      (timer) async {
        await NotificationService.showNotification(
          id: 1002,
          title: '🎰 ¡Dreams Mania Disponible!',
          body: '¡Juega Dreams Mania y gana premios increíbles!',
          payload: 'dreams_mania',
        );
      },
    );
  }

  /// Verificar y programar notificación de cumpleaños
  static void _checkBirthdayNotification(String userName, DateTime birthday) {
    final now = DateTime.now();

    // Si es el cumpleaños hoy
    if (birthday.month == now.month && birthday.day == now.day) {
      // Programar para las 9 AM
      final birthdayTime = DateTime(now.year, now.month, now.day, 9, 0);

      if (now.isBefore(birthdayTime)) {
        final delay = birthdayTime.difference(now);
        Timer(delay, () async {
          await NotificationService.showNotification(
            id: 999,
            title: '🎂 ¡Feliz Cumpleaños, $userName!',
            body:
                'Te regalamos 5000 puntos Dreams para celebrar tu día especial. ¡Disfruta!',
            payload: 'birthday',
          );
        });
      }
    }
  }

  /// Mostrar notificación de bienvenida solo la primera vez
  static Future<void> _showWelcomeNotificationOnce(
    String userName,
    String userLevel,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownWelcome =
        prefs.getBool('hasShownWelcomeNotification') ?? false;

    if (hasShownWelcome) {
      return; // Ya se mostró antes, no volver a mostrar
    }

    // Marcar como mostrada
    await prefs.setBool('hasShownWelcomeNotification', true);

    // Esperar 5 segundos después de abrir la app
    await Future.delayed(const Duration(seconds: 5));

    await NotificationService.showNotification(
      id: 1000,
      title: '¡Bienvenido a Dreams Club, $userName!',
      body: 'Como miembro $userLevel, tienes acceso a beneficios exclusivos.',
      payload: 'welcome',
    );
  }

  /// Disparar notificación de proximidad al casino
  static Future<void> showProximityNotification(String casinoName) async {
    await NotificationService.showNotification(
      id: 2000,
      title: '📍 ¡Estás cerca de $casinoName!',
      body: 'Aprovecha tu visita y disfruta de nuestros juegos y promociones.',
      payload: 'proximity',
    );
  }

  /// Disparar notificación de logro desbloqueado
  static Future<void> showAchievementNotification(
    String achievementName,
    int points,
  ) async {
    await NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '🏆 ¡Nuevo Logro Desbloqueado!',
      body: 'Has completado "$achievementName". +$points puntos bonus.',
      payload: 'achievement',
      isAchievement: true,
    );
  }

  /// Disparar notificación de premio ganado
  static Future<void> showPrizeWonNotification(
    String prizeName,
    String gameName,
  ) async {
    await NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '🎉 ¡Felicitaciones!',
      body: 'Has ganado "$prizeName" en $gameName. Revisa tus premios.',
      payload: 'prize_won',
    );
  }

  /// Disparar notificación de promoción
  static Future<void> showPromotionNotification(
    String promoTitle,
    String promoDescription,
  ) async {
    await NotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '🎁 $promoTitle',
      body: promoDescription,
      payload: 'promotion',
    );
  }

  /// Cancelar todas las notificaciones programadas
  static void cancelAll() {
    _dailyBonusTimer?.cancel();
    _dreamManiaTimer?.cancel();
    _proximityCheckTimer?.cancel();
  }
}

/// Provider para inicializar notificaciones reales
final realNotificationServiceProvider = Provider<void>((ref) {
  RealNotificationService.initialize(ref);

  ref.onDispose(() {
    RealNotificationService.cancelAll();
  });
});
