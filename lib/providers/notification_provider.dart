import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationState {
  final int count;
  final bool hasUnread;
  final List<String> messages;

  const NotificationState({
    this.count = 0,
    this.hasUnread = false,
    this.messages = const [],
  });

  NotificationState copyWith({
    int? count,
    bool? hasUnread,
    List<String>? messages,
  }) {
    return NotificationState(
      count: count ?? this.count,
      hasUnread: hasUnread ?? this.hasUnread,
      messages: messages ?? this.messages,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  void addNotification(String message) {
    final messages = [...state.messages, message];
    state = state.copyWith(
      count: state.count + 1,
      hasUnread: true,
      messages: messages,
    );
  }

  void clearNotifications() {
    state = const NotificationState();
  }

  void markAsRead() {
    state = state.copyWith(hasUnread: false);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});
