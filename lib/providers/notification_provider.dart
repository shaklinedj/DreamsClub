import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/notification_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier(this.ref) : super([]) {
    _loadInitialNotifications();
  }

  final Ref ref;

  void _loadInitialNotifications() {
    final user = ref.read(userProvider);

    // Mock data based on user
    state = [
      AppNotification(
        id: '1',
        title: '¡Feliz Cumpleaños, ${user.name}!',
        message:
            'Te regalamos 5000 puntos Dreams para celebrar tu día. ¡Ven a disfrutar!',
        type: NotificationType.birthday,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: '2',
        title: 'Estás cerca de Monticello',
        message: 'Aprovecha tu visita. Tienes un cupón de cena 2x1 esperando.',
        type: NotificationType.proximity,
        timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      AppNotification(
        id: '3',
        title: 'Promoción Exclusiva ${user.levelName}',
        message:
            'Solo por hoy: Doble acumulación de puntos en máquinas seleccionadas.',
        type: NotificationType.promo,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
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
    state = [notification, ...state];
  }

  void clearAll() {
    state = [];
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier(ref);
});
