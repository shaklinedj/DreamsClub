import 'dart:async';
import 'dart:convert';

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/notification_service.dart';
import 'package:casinoloyalty_flutter/services/gamification_service.dart';

// IMPORTANT: This file handles the BACKGROUND execution isolate.
// Code here runs separately from the main UI thread.

@pragma('vm:entry-point')
void backgroundServiceOnStart(ServiceInstance service) {
  BackgroundServiceImpl.onStart(service);
}

@pragma('vm:entry-point')
Future<bool> backgroundServiceOnIosBackground(ServiceInstance service) {
  return BackgroundServiceImpl.onIosBackground(service);
}

@pragma('vm:entry-point')
class BackgroundServiceImpl {
  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    // DISABLED FOR MANUAL QR FLOW
    if (true) {
      debugPrint('Background Service DISABLED');
      return;
    }

    /* 
    // 1. Web Check
    if (kIsWeb) {
      debugPrint('Background Service avoided on Web');
      return;
    }

    // 2. Mobile Check
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Background Service avoided on non-mobile platform');
      return;
    }
    */

    /*
    try {
      final service = FlutterBackgroundService();

      /// OPTIONAL, using custom notification channel id
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'my_foreground', // id
        'Dreams Club Background Service', // title
        description: 'Used for background location tracking', // description
        importance: Importance.low, // low importance to prevent vibration
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          // This will be executed when app is in foreground or background in separated isolate
          onStart: backgroundServiceOnStart,

          // auto start service
          autoStart: false,
          isForegroundMode: true,

          notificationChannelId: 'my_foreground',
          initialNotificationTitle: 'Dreams Club',
          initialNotificationContent: 'Buscando casinos cercanos...',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: IosConfiguration(
          // auto start service
          autoStart: false,

          // this will be executed when app is in foreground in separated isolate
          onForeground: backgroundServiceOnStart,

          // you have to enable background fetch capability on xcode project
          onBackground: backgroundServiceOnIosBackground,
        ),
      );
    } catch (e) {
      // Removed 'stack'
      debugPrint('❌ Error initializing Background Service: $e');
      // Do not crash the app
    }
    */
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Only available for flutter 3.0.0 and later
    DartPluginRegistrant.ensureInitialized();

    // The flutterLocalNotificationsPlugin is no longer needed here after removing updateNotification.
    // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    //     FlutterLocalNotificationsPlugin();

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Initialize notification service for the background isolate
    // We need this to show "Welcome" notifications

    // Start listening to location
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Check every 50 meters
    );

    Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) async {
      final prefs = await SharedPreferences.getInstance();

      // Load casinos data from prefs (must be saved by UI thread before starting service)
      final String? casinosJson = prefs.getString('background_casinos_data');
      if (casinosJson == null) return;

      final List<dynamic> casinosList = json.decode(casinosJson);

      // Check proximity using shared logic
      await LocationService.checkProximityAndRegisterVisit(
        currentPosition: position,
        casinosData: casinosList,
        prefs: prefs,
        onVisitDetected: (id, name) async {
          // 1. Update Gamification Data in Background (validates 24h minimum)
          final gamificationService = GamificationService();
          final wasValidVisit =
              await gamificationService.incrementTotalVisitsIfValid();

          if (!wasValidVisit) {
            // Already visited today - show welcome back message but don't process achievements
            await NotificationService.showNotification(
              id: id.hashCode,
              title: '📍 Bienvenido de vuelta',
              body: '$name - Tu progreso de hoy ya fue registrado',
              payload: 'visit_$id',
            );
            return; // Don't process achievements
          }

          // Valid visit - show arrival notification
          await NotificationService.showNotification(
            id: id.hashCode,
            title: '📍 Visita registrada',
            body: '¡Bienvenido a $name! Tu visita ha sido contada.',
            payload: 'visit_$id',
          );

          // 2. Update other gamification data
          await gamificationService.addVisitedCasino(id);
          await gamificationService.updateStreak();

          // 3. Check for Achievements
          final unlocked =
              await gamificationService.checkAndUnlockVisitAchievements();

          for (final achievement in unlocked) {
            await NotificationService.showNotification(
              id: achievement['id'].hashCode,
              title: '🏆 ¡Logro Desbloqueado!',
              body: '${achievement['title']} - +${achievement['points']} pts',
              isAchievement: true,
            );
            // Delay to avoid grouping too tightly
            await Future.delayed(const Duration(milliseconds: 500));
          }

          // 4. Notify UI if alive
          service.invoke(
            'visit_detected',
            {'id': id, 'name': name},
          );
        },
      );

      // Optional: Update notification with "Last check: HH:mm"
      // updateNotification('Active. Ubicación: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
    });
  }
}
