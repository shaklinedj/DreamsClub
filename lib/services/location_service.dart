import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:casinoloyalty_flutter/models/casino_model.dart';

class LocationService {
  static const double casinoProximityMeters =
      500.0; // 500 metros de radio para mejor detección

  StreamSubscription<Position>? _positionStreamSubscription;
  Function(String casinoId)? onCasinoVisit;
  List<Casino> _monitoredCasinos = [];

  // Visitas registradas en la sesión (para evitar spam en pocos segundos)
  final Set<String> _visitedCasinosThisSession = {};
  String _currentDayKey = _todayKey();

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Check if location permission has been granted
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission (only call once on first app launch)
  /// Solicita permisos básicos (whileInUse/always).
  ///
  /// Nota: no intentamos elevar automáticamente a "Siempre" aquí porque puede
  /// causar flujos inestables (múltiples diálogos) y bloqueos en algunos dispositivos.
  /// Para elevar explícitamente usar [requestAlwaysPermission].
  Future<bool> requestLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de ubicación está desactivado');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Primera solicitud: esto mostrará el diálogo de "Mientras se usa" en Android
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Permiso de ubicación denegado permanentemente. Habilítalo en configuración.');
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Solicita elevar el permiso de whileInUse a always
  /// Retorna true si se obtuvo el permiso always
  Future<bool> requestAlwaysPermission() async {
    final current = await Geolocator.checkPermission();

    if (current == LocationPermission.always) {
      return true; // Ya tiene permiso always
    }

    if (current == LocationPermission.whileInUse) {
      // Intentar elevar a always
      final elevated = await Geolocator.requestPermission();
      return elevated == LocationPermission.always;
    }

    return false; // No tiene permisos básicos
  }

  /// Get current location (assumes permission is already granted)
  Future<Position> getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de ubicación está desactivado');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permiso de ubicación denegado permanentemente');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    // Detect mocked location (GPS spoofing)
    if (position.isMocked) {
      throw Exception('Mock location detected');
    }

    return position;
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Inicia el monitoreo de ubicación en segundo plano
  Future<void> startLocationMonitoring({
    required List<Casino> casinos,
    required Function(String casinoId) onCasinoVisit,
  }) async {
    this.onCasinoVisit = onCasinoVisit;
    _monitoredCasinos = casinos;

    final hasPermission = await hasLocationPermission();
    if (!hasPermission) {
      final granted = await requestLocationPermission();
      if (!granted) {
        throw Exception('Permisos de ubicación no otorgados');
      }
    }

    // Comprobación adicional para evitar iniciar si sólo se concedió whileInUse y se requiere background.
    // (Foreground seguirá funcionando; background dependerá de WorkManager en Android y background mode en iOS)
    final currentPermission = await Geolocator.checkPermission();
    if (currentPermission == LocationPermission.whileInUse) {
      // ignore: avoid_print
      print(
          'ℹ️ Permiso whileInUse: el tracking en segundo plano puede estar limitado hasta que el usuario otorgue "Siempre".');
    }

    // Configuración para monitoreo en segundo plano
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Actualizar cada 50 metros
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      // Reset diario si la app sigue abierta de un día para otro
      final today = _todayKey();
      if (today != _currentDayKey) {
        _currentDayKey = today;
        _visitedCasinosThisSession.clear();
      }
      await _checkProximityToCasinos(position);
    });
  }

  /// Detiene el monitoreo de ubicación
  void stopLocationMonitoring() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Static method to check proximity and register visits (can be called from background isolate)
  static Future<void> checkProximityAndRegisterVisit({
    required Position currentPosition,
    required List<dynamic> casinosData, // Accepts generic map or Casino object
    required SharedPreferences prefs,
    Function(String, String)? onVisitDetected,
  }) async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    for (final casino in casinosData) {
      final String id = casino['id']?.toString() ?? '';
      final String nombre = casino['nombre'] as String? ?? 'Casino';
      final double lat = (casino['latitud'] as num?)?.toDouble() ?? 0.0;
      final double long = (casino['longitud'] as num?)?.toDouble() ?? 0.0;

      final double distance = Geolocator.distanceBetween(
        currentPosition.latitude,
        currentPosition.longitude,
        lat,
        long,
      );

      if (distance <= casinoProximityMeters) {
        final lastVisitKey = 'last_visit_$id';
        final lastVisit = prefs.getString(lastVisitKey);

        if (lastVisit != todayStr) {
          // Register visit locally
          await prefs.setString(lastVisitKey, todayStr);

          if (onVisitDetected != null) {
            onVisitDetected(id, nombre);
          }
        }
      }
    }
  }

  /// Verifica si el usuario está cerca de algún casino
  Future<void> _checkProximityToCasinos(Position currentPosition) async {
    final prefs = await SharedPreferences.getInstance();

    // Convert Casino objects to Map for the static method
    final casinosMap = _monitoredCasinos
        .map((c) => {
              'id': c.id,
              'nombre': c.nombre,
              'latitud': c.latitud,
              'longitud': c.longitud,
            })
        .toList();

    await checkProximityAndRegisterVisit(
      currentPosition: currentPosition,
      casinosData: casinosMap,
      prefs: prefs,
      onVisitDetected: (id, name) async {
        // Log para depuración
        // Add to session set to update UI immediately if needed
        _visitedCasinosThisSession.add(id);

        // Notify listener
        onCasinoVisit?.call(id);
      },
    );
  }

  /// Verifica si el usuario está actualmente en un casino
  Future<String?> checkIfInCasino(List<Casino> casinos) async {
    try {
      final position = await getCurrentLocation();

      for (final casino in casinos) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          casino.latitud,
          casino.longitud,
        );

        if (distance <= casinoProximityMeters) {
          return casino.id;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Resetea las visitas de la sesión actual
  void resetSessionVisits() {
    _visitedCasinosThisSession.clear();
  }
}
