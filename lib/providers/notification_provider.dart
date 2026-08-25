import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/notification_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationNotifier extends StateNotifier<List<AppNotification>> {
  NotificationNotifier(this.ref, this._uid) : super([]) {
    _initialize();
  }

  final Ref ref;
  final String _uid;
  StreamSubscription? _firestoreSubscription;

  String get _cacheSuffix => _uid.isEmpty ? 'guest' : _uid;

  String get _welcomeShownKey => 'notification_welcome_shown_$_cacheSuffix';

  String get _removedNotificationsKey =>
      'removed_notifications_list_$_cacheSuffix';

  Set<String> _removedIds = {};

  Future<void> _initialize() async {
    await _loadInitialNotifications();
    _listenToFirestoreNotifications();
  }

  Future<void> _loadInitialNotifications() async {
    final user = ref.read(userProvider);
    final prefs = await SharedPreferences.getInstance();

    final removedList = prefs.getStringList(_removedNotificationsKey) ?? [];
    _removedIds = removedList.toSet();

    // Also load from Firestore for persistence across reinstalls
    if (_uid.isNotEmpty) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final deletedNotifications = data?['deleted_notifications'];
          if (deletedNotifications is List) {
            _removedIds.addAll(deletedNotifications.whereType<String>());
            // Sync back to SharedPreferences
            await prefs.setStringList(
                _removedNotificationsKey, _removedIds.toList());
          }
        }
      } catch (e) {
        // Ignorar silenciosamente
      }
    }

    state = state.where((item) => !_removedIds.contains(item.id)).toList();

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

  Future<void> clearAll() async {
    final idsToClear = state.map((n) => n.id).toList();
    _removedIds.addAll(idsToClear);
    state = [];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_removedNotificationsKey, _removedIds.toList());

    if (_uid.isNotEmpty && idsToClear.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_uid).set(
          {'deleted_notifications': FieldValue.arrayUnion(idsToClear)},
          SetOptions(merge: true),
        );
      } catch (e) {
        // Ignorar silenciosamente
      }
    }
  }

  Future<void> removeNotification(String id) async {
    _removedIds.add(id);
    state = state.where((n) => n.id != id).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_removedNotificationsKey, _removedIds.toList());

    // Sync to Firestore for persistence
    if (_uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(_uid).set(
          {
            'deleted_notifications': FieldValue.arrayUnion([id])
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        // Ignorar silenciosamente
      }
    }
  }

  Future<void> restoreNotification(AppNotification notification) async {
    _removedIds.remove(notification.id);
    addNotification(notification);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_removedNotificationsKey, _removedIds.toList());
  }

  bool isNotificationRemoved(String id) {
    return _removedIds.contains(id);
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

  void _listenToFirestoreNotifications() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final List<AppNotification> firestoreNotifications = [];
      for (final doc in snapshot.docs) {
        if (_removedIds.contains(doc.id)) continue;

        final data = doc.data();
        final createdAt = data['createdAt'];
        final timestamp =
            createdAt is Timestamp ? createdAt.toDate() : DateTime.now();

        NotificationType type = NotificationType.info;
        final typeStr = data['type']?.toString().toLowerCase();
        if (typeStr == 'promo' || typeStr == 'event') {
          type = NotificationType.promo;
        } else if (typeStr == 'birthday') {
          type = NotificationType.birthday;
        }

        firestoreNotifications.add(AppNotification(
          id: doc.id,
          title: data['title']?.toString() ?? 'Dreams Club',
          message: data['body']?.toString() ?? '',
          type: type,
          timestamp: timestamp,
          actionRoute: '/notification-detail/${doc.id}',
          actionData: {
            'imageUrl': data['imageUrl'],
          },
        ));
      }

      final currentMap = {for (var n in state) n.id: n};

      for (final fn in firestoreNotifications) {
        if (currentMap.containsKey(fn.id)) {
          final existing = currentMap[fn.id]!;
          currentMap[fn.id] = fn.copyWith(isRead: existing.isRead);
        } else {
          currentMap[fn.id] = fn;
        }
      }

      state = currentMap.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationNotifier, List<AppNotification>>((ref) {
  final uid =
      ref.watch(authProvider.select((state) => state.firebaseUser?.uid));
  return NotificationNotifier(ref, uid ?? '');
});
