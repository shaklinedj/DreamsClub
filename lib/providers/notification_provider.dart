import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/notification_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier(this.ref) : super([]) {
    _loadInitialNotifications();
  }

  final Ref ref;

  // Keys for tracking shown notifications
  static const _welcomeShownKey = 'notification_welcome_shown';

  Future<void> _loadInitialNotifications() async {
    final user = ref.read(userProvider);
    final prefs = await SharedPreferences.getInstance();

    // Static notifications (always available in the list)
    state = [];

    // Birthday notification (only on actual birthday)
    if (user.birthday != null &&
        user.birthday!.day == DateTime.now().day &&
        user.birthday!.month == DateTime.now().month) {
      state = [
        AppNotification(
          id: 'birthday_${DateTime.now().year}',
          title: '¡Feliz Cumpleaños, ${user.name}!',
          message:
              'Te regalamos 5000 puntos Dreams para celebrar tu día. ¡Ven a disfrutar!',
          type: NotificationType.birthday,
          timestamp: DateTime.now(),
          actionRoute: '/slot-machine',
        ),
        ...state,
      ];
    }

    // Check if welcome notification was already shown (only show ONCE ever)
    final welcomeShown = prefs.getBool(_welcomeShownKey) ?? false;
    if (!welcomeShown) {
      // Mark as shown so it never triggers again
      await prefs.setBool(_welcomeShownKey, true);
      // Note: We don't trigger a push notification for welcome anymore
      // The welcome is handled by the splash screen UI
    }
  }

  void markAsRead(String id) {
    state = [
      for (final notification in state)
        if (notification.id == id)
          notification.copyWith(isRead: true)
        else
          notification
    ];
  }

  void addNotification(AppNotification notification) {
    // Avoid duplicates
    if (state.any((n) => n.id == notification.id)) return;
    state = [notification, ...state];
  }

  void clearAll() {
    state = [];
  }

  /// Add a proximity notification (called when user arrives at casino)
  /// Only adds once per visit session
  void addProximityNotification(String casinoName) {
    final id = 'proximity_${DateTime.now().millisecondsSinceEpoch}';
    // Only add if we don't have a recent proximity notification
    final hasRecent = state.any((n) =>
        n.type == NotificationType.proximity &&
        n.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 1))));

    if (!hasRecent) {
      addNotification(AppNotification(
        id: id,
        title: '📍 Llegaste a $casinoName',
        message: 'Bienvenido. Abre la app para acumular puntos y jugar.',
        type: NotificationType.proximity,
        timestamp: DateTime.now(),
        actionRoute: '/home',
      ));
    }
  }

  /// Add an achievement notification
  void addAchievementNotification(String title, String message) {
    addNotification(AppNotification(
      id: 'achievement_${DateTime.now().millisecondsSinceEpoch}',
      title: '🏆 $title',
      message: message,
      type: NotificationType.achievement,
      timestamp: DateTime.now(),
      actionRoute: '/my-prizes',
    ));
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier(ref);
});
