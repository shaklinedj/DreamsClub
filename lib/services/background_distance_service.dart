import 'dart:math';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart';

class BackgroundDistanceService {
  static const String taskName = 'distanceCheckTask';
  static const int checkIntervalMinutes = 15; // Chequear cada 15 minutos
  static const double distanceThresholdKm =
      100.0; // Distancia umbral en km (notificación si estás a más de 100km)

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the service and optionally provide a callback for notification taps.
  static Future<void> initialize(
      {void Function(NotificationResponse)? onNotificationResponse}) async {
    // Inicializar notificaciones
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationResponse,
    );

    // Solo inicializar WorkManager si las notificaciones están habilitadas
    final isEnabled =
        await UserProfileService().areDistanceNotificationsEnabled();
    if (!isEnabled) return;

    // Inicializar WorkManager
    await Workmanager().initialize(callbackDispatcher);

    // Registrar tarea periódica
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(minutes: checkIntervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> cancelTask() async {
    await Workmanager().cancelByUniqueName(taskName);
  }

  static Future<void> enableNotifications() async {
    await UserProfileService().setDistanceNotificationsEnabled(true);
    await initialize();
  }

  static Future<void> disableNotifications() async {
    await UserProfileService().setDistanceNotificationsEnabled(false);
    await cancelTask();
  }

  static Future<bool> areNotificationsEnabled() async {
    return await UserProfileService().areDistanceNotificationsEnabled();
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == BackgroundDistanceService.taskName) {
        await _performDistanceCheck();
      }
      return true;
    } catch (e) {
      developer.log('Error in background task: $e',
          name: 'BackgroundDistanceService');
      return false;
    }
  });
}

Future<void> _performDistanceCheck() async {
  try {
    // Obtener casino favorito
    final favoriteId = await UserProfileService().loadFavoriteCasinoId();
    if (favoriteId == null) return;

    // Obtener casinos
    final casinoService = CasinoService();
    final List<Casino> casinos = await casinoService.getAllCasinos();
    final Casino favoriteCasino = casinos.firstWhere((c) => c.id == favoriteId);

    // Obtener ubicación actual
    final locationService = LocationService();
    final Position position = await locationService.getCurrentLocation();

    // Calcular distancia
    final distance = _calculateDistance(
      position.latitude,
      position.longitude,
      favoriteCasino.latitud,
      favoriteCasino.longitud,
    );

    // Si distancia > umbral, mostrar notificación
    if (distance > BackgroundDistanceService.distanceThresholdKm) {
      await _showNotification(favoriteCasino.nombre, distance);
    }
  } catch (e) {
    developer.log('Error checking distance: $e',
        name: 'BackgroundDistanceService');
  }
}

double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Radio de la Tierra en km

  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);

  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) *
          cos(_degreesToRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

Future<void> _showNotification(String casinoName, double distance) async {
  final androidDetails = AndroidNotificationDetails(
    'distance_channel',
    'Chequeo de Distancia',
    channelDescription:
        'Notificaciones cuando estás lejos de tu casino favorito',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 250, 250, 250]),
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

  final distanceRounded = distance.round();
  final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  await BackgroundDistanceService._notificationsPlugin.show(
    notificationId,
    '¡Estás lejos de $casinoName!',
    'Te encuentras a ${distanceRounded}km de distancia. ¿Quieres visitar otro casino cercano?',
    details,
    payload: 'distance_alert',
  );
}
