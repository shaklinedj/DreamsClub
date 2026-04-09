import 'dart:math';
import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';

/// Simple service for spin wheel game logic (prizes only).
/// Game availability is now managed by gameAvailabilityProvider.
class SpinWheelService {
  static const int spinCostPoints = 100;

  /// Spin the wheel and return a random prize based on probability
  Future<Prize> spinWheel() async {
    int totalProbability =
        mockPrizes.fold(0, (sum, prize) => sum + prize.probability);

    final random = Random();
    int randomValue = random.nextInt(totalProbability);

    int cumulative = 0;
    for (var prize in mockPrizes) {
      cumulative += prize.probability;
      if (randomValue < cumulative) {
        return prize;
      }
    }

    return mockPrizes.last;
  }

  /// Create a WonPrize from spin result
  WonPrize createWonPrize({
    required Prize prize,
    required String casinoId,
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
