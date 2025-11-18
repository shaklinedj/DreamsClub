import 'dart:math';
import 'dart:developer' as developer;


import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/user_prefs.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundDistanceService {
  static const String taskName = 'distanceCheckTask';
  static const int checkIntervalMinutes = 15; // Chequear cada 15 minutos
  static const String _prefsKey = 'distance_notifications_enabled';

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Inicializar notificaciones
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    // Solo inicializar WorkManager si las notificaciones están habilitadas
    final isEnabled = await UserPreferences.getBool(_prefsKey) ?? false;
    if (!isEnabled) return;

    // Inicializar WorkManager
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    // Registrar tarea periódica
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: const Duration(minutes: checkIntervalMinutes),
      constraints: Constraints(
        networkType: NetworkType.not_required,
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
    await UserPreferences.setBool(_prefsKey, true);
    await initialize();
  }

  static Future<void> disableNotifications() async {
    await UserPreferences.setBool(_prefsKey, false);
    await cancelTask();
  }

  static Future<bool> areNotificationsEnabled() async {
    return await UserPreferences.getBool(_prefsKey) ?? false;
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
      developer.log('Error in background task: $e', name: 'BackgroundDistanceService');
      return false;
    }
  });
}

Future<void> _performDistanceCheck() async {
  try {
    // Obtener casino favorito
    final favoriteId = await UserPreferences.getFavoriteCasino();
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

    // Si distancia > 60km, mostrar notificación
    if (distance > 60.0) {
      await _showNotification(favoriteCasino.nombre, distance);
    }
  } catch (e) {
    developer.log('Error checking distance: $e', name: 'BackgroundDistanceService');
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
  const androidDetails = AndroidNotificationDetails(
    'distance_channel',
    'Chequeo de Distancia',
    channelDescription: 'Notificaciones cuando estás lejos de tu casino favorito',
    importance: Importance.high,
    priority: Priority.high,
    showWhen: true,
  );

  const iosDetails = DarwinNotificationDetails();

  const details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  final distanceRounded = distance.round();

  await BackgroundDistanceService._notificationsPlugin.show(
    0,
    '¡Estás lejos de $casinoName!',
    'Te encuentras a ${distanceRounded}km de distancia. ¿Quieres visitar otro casino cercano?',
    details,
  );
}