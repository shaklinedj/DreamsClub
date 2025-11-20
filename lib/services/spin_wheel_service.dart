import 'dart:math';
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpinWheelService {
  final LocationService _locationService = LocationService();
  final CasinoService _casinoService = CasinoService();
  
  static const int spinCostPoints = 100;
  static const double maxDistanceMeters = 200.0; // 200m radius

  /// Check if user can play the spin wheel today
  Future<SpinEligibility> canPlayToday(int userPoints) async {
    // 1. Check if already played today
    final prefs = await SharedPreferences.getInstance();
    final lastSpinDate = prefs.getString('last_spin_date');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (lastSpinDate == today) {
      return SpinEligibility(
        canPlay: false,
        reason: 'Ya jugaste hoy. Vuelve mañana! 🎰',
      );
    }

    // 2. Check points
    if (userPoints < spinCostPoints) {
      return SpinEligibility(
        canPlay: false,
        reason: 'Necesitas $spinCostPoints puntos Dreams para jugar',
      );
    }

    // 3. Check GPS location
    try {
      final position = await _locationService.getCurrentLocation();
      final nearestCasino = await _casinoService.getNearestCasino(
        position.latitude,
        position.longitude,
      );
      
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        nearestCasino.latitud,
        nearestCasino.longitud,
      );

      if (distance > maxDistanceMeters) {
        return SpinEligibility(
          canPlay: false,
          reason: 'Debes estar en un casino Dreams para jugar 📍',
          nearestCasino: nearestCasino,
          distanceMeters: distance,
        );
      }

      return SpinEligibility(
        canPlay: true,
        reason: '¡Listo para jugar!',
        nearestCasino: nearestCasino,
        distanceMeters: distance,
      );
      
    } catch (e) {
      return SpinEligibility(
        canPlay: false,
        reason: 'Error al obtener tu ubicación. Activa el GPS.',
      );
    }
  }

  /// Spin the wheel and return a random prize
  Future<Prize> spinWheel() async {
    // Calculate cumulative probabilities
    int totalProbability = mockPrizes.fold(0, (sum, prize) => sum + prize.probability);
    
    // Generate random number
    final random = Random();
    int randomValue = random.nextInt(totalProbability);
    
    // Select prize based on probability
    int cumulative = 0;
    for (var prize in mockPrizes) {
      cumulative += prize.probability;
      if (randomValue < cumulative) {
        return prize;
      }
    }
    
    // Fallback (should never reach)
    return mockPrizes.last;
  }

  /// Save that user played today
  Future<void> recordSpinToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('last_spin_date', today);
  }

  /// Create a WonPrize from spin result
  WonPrize createWonPrize({
    required Prize prize,
    required int casinoId,
  }) {
    final id = '${DateTime.now().millisecondsSinceEpoch}';
    final qrCode = 'DREAMS-${prize.id}-$id-${Random().nextInt(9999)}';
    
    return WonPrize(
      id: id,
      prize: prize,
      wonAt: DateTime.now(),
      casinoId: casinoId,
      qrCode: qrCode,
    );
  }
}

class SpinEligibility {
  final bool canPlay;
  final String reason;
  final Casino? nearestCasino;
  final double? distanceMeters;

  SpinEligibility({
    required this.canPlay,
    required this.reason,
    this.nearestCasino,
    this.distanceMeters,
  });

  String get distanceText {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.toInt()}m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
  }
}
