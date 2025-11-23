import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/notification_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/notification_service.dart';

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier(this.ref) : super([]) {
    _loadInitialNotifications();
  }

  final Ref ref;

  void _loadInitialNotifications() {
    final user = ref.read(userProvider);

    // Mock data based on user
    state = [
      if (user.birthday != null &&
          user.birthday!.day == DateTime.now().day &&
          user.birthday!.month == DateTime.now().month)
        AppNotification(
          id: 'birthday_${DateTime.now().year}',
          title: '¡Feliz Cumpleaños, ${user.name}!',
          message:
              'Te regalamos 5000 puntos Dreams para celebrar tu día. ¡Ven a disfrutar!',
          type: NotificationType.birthday,
          timestamp: DateTime.now(),
        ),
    ];

    // Add other notifications
    state = [
      ...state,
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

    if (user.birthday != null &&
        user.birthday!.day == DateTime.now().day &&
        user.birthday!.month == DateTime.now().month) {
      _triggerBirthdayNotification(user.name);
    }

    // Trigger sample event notification for demonstration
    _triggerEventNotification();
  }

  Future<void> _triggerEventNotification() async {
    await NotificationService.showNotification(
      id: 1000,
      title: '🎉 Nuevo Evento Disponible',
      body: 'Torneo de Póker este viernes. ¡Inscríbete ahora y gana premios!',
    );
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

  Future<void> _triggerBirthdayNotification(String userName) async {
    await NotificationService.showNotification(
      id: 999,
      title: '¡Feliz Cumpleaños, $userName!',
      body:
          'Te regalamos 5000 puntos Dreams para celebrar tu día. ¡Ven a disfrutar!',
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  return NotificationNotifier(ref);
});
