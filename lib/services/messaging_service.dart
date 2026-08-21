import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:casinoloyalty_flutter/services/notification_service.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access other Firebase services here, you must initialize App again
  // await Firebase.initializeApp();
  AppLogger.debug('Handling a background message: ${message.messageId}');
}

class MessagingService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // 1. Request Permission
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info(
          'User granted permission: ${settings.authorizationStatus}');

      // 2. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 3. Get Token and register listener for Auth Changes
      final token = await _firebaseMessaging.getToken();
      AppLogger.info('FCM Token: $token');
      if (token != null) {
        FirebaseAuth.instance.authStateChanges().listen((user) async {
          if (user != null) {
            try {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'fcmToken': token,
              }, SetOptions(merge: true));
              AppLogger.info('Successfully saved FCM token to Firestore for user: ${user.uid}');
            } catch (e) {
              AppLogger.error('Failed to save FCM token', e);
            }
          }
        });
      }

      // 4. Foreground Message Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.debug('Got a message whilst in the foreground!');
        AppLogger.debug('Message data: ${message.data}');

        if (message.notification != null) {
          AppLogger.debug(
              'Message also contained a notification: ${message.notification}');

          // Show local notification
          NotificationService.showNotification(
            id: message.hashCode,
            title: message.notification?.title ?? 'Notificación',
            body: message.notification?.body ?? '',
            payload: message.data['route'] ??
                message.data['payload'], // Custom payload support
          );
        }
      });

      // 5. App Opened from Notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.debug('A new onMessageOpenedApp event was published!');
        final route = message.data['route'];
        if (route != null) {
          NotificationService.onNotificationTap?.call(route);
        }
      });

      // 6. Check if app was opened from a terminated state
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.debug('App opened from terminated state via notification');
        final route = initialMessage.data['route'];
        if (route != null) {
          // We might need a slight delay or a way to pass this to the router after init
          // For now, let's just log it. The router might need a separate mechanism.
          // Or simpler: rely on the onNotificationTap callback being set early in main
          Future.delayed(const Duration(seconds: 1), () {
            NotificationService.onNotificationTap?.call(route);
          });
        }
      }
    } catch (e) {
      AppLogger.error('Error initializing MessagingService', e);
    }
  }
}
