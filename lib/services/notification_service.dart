import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/services.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Optional callback invoked when the user taps a notification.
  ///
  /// The payload can be a route (e.g. `/promotions`) or a short key.
  static void Function(String? payload)? onNotificationTap;

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap?.call(details.payload);
      },
    );

    // Clear any restored notifications from Android auto backup
    try {
      await _notificationsPlugin.cancelAll();
    } catch (_) {}

    // Inicia el listener en tiempo real de alertas desde el panel (Plan Spark)
    listenToLiveBroadcasts();
  }

  /// Escucha en tiempo real las notificaciones enviadas desde el Dashboard con segmentación de audiencia
  static void listenToLiveBroadcasts() {
    FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        final createdAt = data['createdAt'];
        if (createdAt is Timestamp) {
          final age = DateTime.now().difference(createdAt.toDate());
          if (age.inMinutes < 5) {
            final isEligible = await _checkUserSegmentEligibility(data);
            if (isEligible) {
              showNotification(
                id: doc.id.hashCode,
                title: data['title']?.toString() ?? 'Dreams Club Coyhaique',
                body: data['body']?.toString() ?? '',
                payload: '/notification-detail/${doc.id}',
              );
            }
          }
        }
      }
    }, onError: (e) {
      // Ignorar errores silenciosamente si no hay red
    });
  }

  /// Verifica si el usuario actual cumple con el segmento objetivo enviado por el Admin
  static Future<bool> _checkUserSegmentEligibility(Map<String, dynamic> data) async {
    final isBroadcast = data['broadcast'] == true;
    if (isBroadcast) return true;

    final targetSegment = data['targetSegment'] as Map<String, dynamic>?;
    if (targetSegment == null) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('user_email') ?? '';
      
      if (userEmail.isEmpty) return true;

      final activeUserDoc = await FirebaseFirestore.instance.collection('users').doc(userEmail).get();
      if (!activeUserDoc.exists) return true;

      final userData = activeUserDoc.data() ?? {};

      // 1. Consent Filter
      final consentOnly = targetSegment['consentOnly'] as bool? ?? false;
      final contactConsent = userData['contactConsent'] ?? userData['wantsContact'] ?? true;
      if (consentOnly && contactConsent != true) {
        return false;
      }

      // 2. Streak Filter
      final streakFilter = targetSegment['streak'] as String? ?? 'all';
      final streak = (userData['currentStreak'] as num?)?.toInt() ?? (userData['streak'] as num?)?.toInt() ?? 0;
      if (streakFilter == 'active' && streak < 1) return false;
      if (streakFilter == 'high' && streak < 5) return false;
      if (streakFilter == 'vip' && streak < 10) return false;
      if (streakFilter == 'none' && streak > 0) return false;

      // 3. Presence / Inactivity Filter
      final presenceFilter = targetSegment['presence'] as String? ?? 'all';
      final lastVisitRaw = userData['lastVisit'];
      DateTime? lastVisitDate;
      if (lastVisitRaw is Timestamp) {
        lastVisitDate = lastVisitRaw.toDate();
      } else if (lastVisitRaw is String) {
        lastVisitDate = DateTime.tryParse(lastVisitRaw);
      }

      final daysInactive = lastVisitDate == null ? 999 : DateTime.now().difference(lastVisitDate).inDays;
      final isPresentToday = userData['isPresentToday'] as bool? ?? false;

      if (presenceFilter == 'today' && !isPresentToday && daysInactive > 0) {
        return false;
      }
      if (presenceFilter == 'inactive5' && daysInactive < 5) {
        return false;
      }
      if (presenceFilter == 'inactive10' && daysInactive < 10) {
        return false;
      }

      return true;
    } catch (e) {
      return true;
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isAchievement = false,
  }) async {
    // Trigger foreground physical vibration feedback
    HapticFeedback.vibrate();

    final androidDetails = AndroidNotificationDetails(
      isAchievement ? 'achievements_channel_v2' : 'dreams_club_channel_v2',
      isAchievement ? 'Logros Dreams Club' : 'Notificaciones Dreams Club',
      channelDescription: isAchievement
          ? 'Notificaciones de logros y recompensas desbloqueados'
          : 'Notificaciones generales de la aplicación',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dreams_mania_channel',
      'Dreams Mania',
      channelDescription: 'Notificaciones de Dreams Mania disponible',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
