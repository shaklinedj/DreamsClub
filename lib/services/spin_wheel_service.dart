import 'dart:math';
import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';

class SpinWheelService {
  static const int spinCostPoints = 100;

  /// Spin the wheel and return a random prize based on probability
  Future<Prize> spinWheel({List<Prize>? customPrizes}) async {
    final pool = (customPrizes != null && customPrizes.isNotEmpty)
        ? customPrizes
        : await PrizeService().getPrizesCatalog();

    int totalProbability = pool.fold(0, (sum, prize) => sum + prize.probability);
    if (totalProbability <= 0) totalProbability = 100;

    final random = Random.secure();
    int randomValue = random.nextInt(totalProbability);

    int cumulative = 0;
    for (var prize in pool) {
      cumulative += prize.probability;
      if (randomValue < cumulative) {
        return prize;
      }
    }

    return pool.last;
  }

  /// Create a WonPrize from spin result with unique alphanumeric code
  WonPrize createWonPrize({
    required Prize prize,
    required String casinoId,
    String userId = '',
    String userName = '',
    String userEmail = '',
    String userRut = '',
    String gameSource = 'roulette',
  }) {
    final id = 'wp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
    final code = PrizeService.generateRedemptionCode();

    return WonPrize(
      id: id,
      prize: prize,
      redemptionCode: code,
      wonAt: DateTime.now(),
      casinoId: casinoId,
      qrCode: code,
      status: 'disponible',
      gameSource: gameSource,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userRut: userRut,
    );
  }
}
