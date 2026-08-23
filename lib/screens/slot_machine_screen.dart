import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_availability_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_history_provider.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:casinoloyalty_flutter/services/spin_wheel_service.dart';
import 'package:casinoloyalty_flutter/widgets/game_victory_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SlotMachineScreen extends ConsumerStatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  ConsumerState<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends ConsumerState<SlotMachineScreen> {
  // Slot Machine State
  final List<String> _symbols = ['🍒', '🍋', '🍇', '💎', '7️⃣', '🔔'];
  late FixedExtentScrollController _controller1;
  late FixedExtentScrollController _controller2;
  late FixedExtentScrollController _controller3;
  bool _isSpinning = false;
  String _resultMessage = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PrizeService _prizeService = PrizeService();
  final SpinWheelService _spinWheelService = SpinWheelService();

  @override
  void initState() {
    super.initState();
    _controller1 = FixedExtentScrollController(initialItem: 0);
    _controller2 = FixedExtentScrollController(initialItem: 1);
    _controller3 = FixedExtentScrollController(initialItem: 2);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _spin() async {
    if (_isSpinning) return;

    // Check game availability from Firebase config
    final gameAvailability = ref.read(gameAvailabilityProvider('slots'));
    if (gameAvailability.status != GameStatus.available) {
      setState(() {
        _resultMessage = gameAvailability.message ?? 'No puedes jugar ahora';
      });
      return;
    }

    // Record the play in history (for frequency check)
    ref.read(gameHistoryProvider.notifier).recordPlay('slots');

    setState(() {
      _isSpinning = true;
      _resultMessage = '';
    });

    // Play spin sound
    try {
      await _audioPlayer.play(AssetSource('sounds/spin.wav'));
    } catch (_) {}

    // Force a win!
    final random = Random();
    // 70% chance of Two match, 30% chance of Jackpot
    final isJackpot = random.nextDouble() < 0.3;
    final result1 = random.nextInt(_symbols.length);
    final result2 = isJackpot ? result1 : result1;
    final result3 = isJackpot
        ? result1
        : (random.nextDouble() < 0.7
            ? result1
            : random.nextInt(_symbols.length));

    // Animate reels
    await Future.wait([
      _animateReel(_controller1, result1, 1000),
      _animateReel(_controller2, result2, 1500),
      _animateReel(_controller3, result3, 2000),
    ]);

    // Check for win
    final sym1 = _symbols[result1];
    final sym2 = _symbols[result2];
    final sym3 = _symbols[result3];

    WonPrize? wonPhysicalPrize;
    final user = ref.read(userProvider);
    final locationState = ref.read(locationProvider);
    final casinoId = locationState.nearestCasino?.id ?? '4';

    if (sym1 == sym2 && sym2 == sym3) {
      // Jackpot! Award dynamic physical prize from catalog
      try {
        final catalog = await _prizeService.getPrizesCatalog();
        final selectedPrize = catalog.isNotEmpty ? catalog[random.nextInt(catalog.length)] : null;
        if (selectedPrize != null) {
          wonPhysicalPrize = _spinWheelService.createWonPrize(
            prize: selectedPrize,
            casinoId: casinoId,
            userId: FirebaseAuth.instance.currentUser?.uid ?? (user.email.isNotEmpty ? user.email : (user.rut ?? '')),
            userName: user.name,
            userEmail: user.email,
            userRut: user.rut ?? '',
            gameSource: 'slots',
          );
          await _prizeService.saveWonPrize(wonPhysicalPrize);
        }
      } catch (_) {}

      _resultMessage = '🎉 ¡JACKPOT! Ganaste ${wonPhysicalPrize?.prize.name ?? 'un premio'}';
      try {
        await _audioPlayer.play(AssetSource('sounds/win.wav'));
      } catch (_) {}
    } else if (sym1 == sym2 || sym2 == sym3 || sym1 == sym3) {
      // Two match! Award dynamic physical prize from catalog
      try {
        final catalog = await _prizeService.getPrizesCatalog();
        final selectedPrize = catalog.isNotEmpty ? catalog[random.nextInt(catalog.length)] : null;
        if (selectedPrize != null) {
          wonPhysicalPrize = _spinWheelService.createWonPrize(
            prize: selectedPrize,
            casinoId: casinoId,
            userId: FirebaseAuth.instance.currentUser?.uid ?? (user.email.isNotEmpty ? user.email : (user.rut ?? '')),
            userName: user.name,
            userEmail: user.email,
            userRut: user.rut ?? '',
            gameSource: 'slots',
          );
          await _prizeService.saveWonPrize(wonPhysicalPrize);
        }
      } catch (_) {}

      _resultMessage = '🎊 ¡Dos iguales! Ganaste ${wonPhysicalPrize?.prize.name ?? 'un premio'}';
      try {
        await _audioPlayer.play(AssetSource('sounds/coins.wav'));
      } catch (_) {}
    } else {
      _resultMessage = '¡Casi lo logras!';
    }

    setState(() {
      _isSpinning = false;
    });

    // Show victory dialog if won
    if (mounted && wonPhysicalPrize != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => GameVictoryDialog(
          gameName: 'Máquina de Premios',
          prizeName: wonPhysicalPrize?.prize.name,
          prizeIcon: wonPhysicalPrize?.prize.icon,
          redemptionCode: wonPhysicalPrize?.redemptionCode,
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
  }

  Future<void> _animateReel(
      FixedExtentScrollController controller, int targetIndex, int durationMs) {
    final currentItem = controller.selectedItem;
    final totalItems = _symbols.length;
    final extraSpins = 3 * totalItems;
    final targetPosition = currentItem + extraSpins + (targetIndex - (currentItem % totalItems));

    return controller.animateToItem(
      targetPosition,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final gameAvailability = ref.watch(gameAvailabilityProvider('slots'));
    final locationState = ref.watch(locationProvider);

    final bool canPlay = gameAvailability.status == GameStatus.available;

    String statusMessage;
    Color statusColor;

    switch (gameAvailability.status) {
      case GameStatus.available:
        statusMessage = locationState.nearestCasino != null
            ? 'Casino: ${locationState.nearestCasino!.nombre}'
            : '¡Listo para jugar!';
        statusColor = Colors.green;
        break;
      case GameStatus.lockedLocation:
        statusMessage = gameAvailability.message ?? 'Debes estar en un casino';
        statusColor = Colors.red;
        break;
      case GameStatus.lockedFrequency:
        statusMessage = gameAvailability.message ?? 'Cooldown activo';
        statusColor = Colors.orange;
        break;
      case GameStatus.lockedTime:
        statusMessage = gameAvailability.message ?? 'No disponible en este horario';
        statusColor = Colors.grey;
        break;
      case GameStatus.lockedStreak:
        statusMessage = gameAvailability.message ?? 'Racha insuficiente';
        statusColor = Colors.amber;
        break;
      case GameStatus.maintenance:
        statusMessage = gameAvailability.message ?? 'En mantenimiento';
        statusColor = Colors.grey;
        break;
      case GameStatus.loading:
        statusMessage = 'Cargando...';
        statusColor = Colors.grey;
        break;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dreams Logo
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'DREAMS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                  Text(
                    'CASINO',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 16,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),

            // Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      canPlay ? Icons.check_circle : Icons.info,
                      color: statusColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        statusMessage,
                        style: TextStyle(color: statusColor, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Slot Machine Display
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReel(_controller1),
                  Container(width: 2, color: Colors.grey[800]),
                  _buildReel(_controller2),
                  Container(width: 2, color: Colors.grey[800]),
                  _buildReel(_controller3),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Result Message
            Text(
              _resultMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            // Play Button
            GestureDetector(
              onTap: canPlay && !_isSpinning ? _spin : null,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canPlay && !_isSpinning ? primaryColor : Colors.grey,
                  boxShadow: [
                    if (canPlay && !_isSpinning)
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              canPlay ? 'JUGAR' : 'NO DISPONIBLE',
              style: const TextStyle(
                color: Colors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReel(FixedExtentScrollController controller) {
    return SizedBox(
      width: 60,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 80,
        physics: const FixedExtentScrollPhysics(),
        childDelegate: ListWheelChildLoopingListDelegate(
          children: _symbols.map((symbol) {
            return Center(
              child: Text(
                symbol,
                style: const TextStyle(fontSize: 40),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
