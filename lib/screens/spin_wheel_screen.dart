import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_availability_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:casinoloyalty_flutter/services/spin_wheel_service.dart';
import 'package:casinoloyalty_flutter/widgets/spin_wheel_widget.dart';
import 'package:casinoloyalty_flutter/widgets/game_victory_dialog.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/providers/game_history_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen> {
  final SpinWheelService _spinService = SpinWheelService();
  final PrizeService _prizeService = PrizeService();
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

  bool _isSpinning = false;

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    setState(() => _isSpinning = true);
  }

  void _onSpinComplete(Prize prize) async {
    if (!mounted) return;

    ref.read(gameHistoryProvider.notifier).recordPlay('roulette');

    final locationState = ref.read(locationProvider);
    final user = ref.read(userProvider);
    final casinoId = locationState.nearestCasino?.id ?? '4';

    final wonPrize = _spinService.createWonPrize(
      prize: prize,
      casinoId: casinoId,
      userId: FirebaseAuth.instance.currentUser?.uid ?? (user.email.isNotEmpty ? user.email : (user.rut ?? '')),
      userName: user.name,
      userEmail: user.email,
      userRut: user.rut ?? '',
      gameSource: 'roulette',
    );
    await _prizeService.saveWonPrize(wonPrize);

    _confettiController.play();

    setState(() => _isSpinning = false);

    if (mounted) {
      _showPrizeDialog(wonPrize);
    }
  }

  void _showPrizeDialog(WonPrize wonPrize) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => GameVictoryDialog(
        gameName: 'Ruleta de la Suerte',
        prizeName: wonPrize.prize.name,
        prizeIcon: wonPrize.prize.icon,
        redemptionCode: wonPrize.redemptionCode,
        viewButtonLabel: 'VER EN MIS PREMIOS',
        onViewPressed: () {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              context.push('/my-prizes');
            }
          });
        },
        onClose: () {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameAvailability = ref.watch(gameAvailabilityProvider('roulette'));
    final locationState = ref.watch(locationProvider);

    final bool canPlay = gameAvailability.status == GameStatus.available;

    String statusMessage;
    Color statusColor;
    IconData statusIcon;

    switch (gameAvailability.status) {
      case GameStatus.available:
        statusMessage = '¡Listo para jugar!';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case GameStatus.lockedLocation:
        statusMessage = gameAvailability.message ?? 'Debes estar en un casino';
        statusColor = Colors.red;
        statusIcon = Icons.location_off;
        break;
      case GameStatus.lockedFrequency:
        statusMessage = gameAvailability.message ?? 'Ya jugaste. Espera el cooldown';
        statusColor = Colors.orange;
        statusIcon = Icons.timer;
        break;
      case GameStatus.lockedTime:
        statusMessage = gameAvailability.message ?? 'No disponible en este horario o día';
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
        break;
      case GameStatus.lockedStreak:
        statusMessage = gameAvailability.message ?? 'Racha insuficiente';
        statusColor = Colors.amber;
        statusIcon = Icons.local_fire_department;
        break;
      case GameStatus.maintenance:
        statusMessage = gameAvailability.message ?? 'En mantenimiento';
        statusColor = Colors.grey;
        statusIcon = Icons.build;
        break;
      case GameStatus.loading:
        statusMessage = 'Cargando...';
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruleta de Premios'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, color: statusColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                statusMessage,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (locationState.nearestCasino != null)
                                Text(
                                  'Casino: ${locationState.nearestCasino!.nombre}',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0xFFD4AF37), width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.arrow_drop_down,
                            size: 40, color: Color(0xFFD4AF37)),
                        SpinWheelWidget(
                          prizes: mockPrizes,
                          isSpinning: _isSpinning,
                          onSpinComplete: _onSpinComplete,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canPlay && !_isSpinning ? _spin : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isSpinning ? 'GIRANDO...' : 'GIRAR RULETA',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
