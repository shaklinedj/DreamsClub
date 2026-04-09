import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_availability_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_history_provider.dart';
import 'package:casinoloyalty_flutter/widgets/game_victory_dialog.dart';
import 'package:go_router/go_router.dart';

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

  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller1 = FixedExtentScrollController();
    _controller2 = FixedExtentScrollController();
    _controller3 = FixedExtentScrollController();
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

    int pointsWon = 0;
    if (sym1 == sym2 && sym2 == sym3) {
      // Jackpot!
      pointsWon = sym1 == '7️⃣' ? 10000 : 5000;
      _resultMessage = '🎉 ¡JACKPOT! +$pointsWon puntos';
      try {
        await _audioPlayer.play(AssetSource('sounds/win.wav'));
      } catch (_) {}
    } else if (sym1 == sym2 || sym2 == sym3 || sym1 == sym3) {
      // Two match
      pointsWon = 1000;
      _resultMessage = '🎊 ¡Dos iguales! +$pointsWon puntos';
      try {
        await _audioPlayer.play(AssetSource('sounds/coins.wav'));
      } catch (_) {}
    } else {
      // Fallback (rare due to forced logic)
      _resultMessage = '¡Casi lo logras!';
    }

    if (pointsWon > 0) {
      await ref.read(userProvider.notifier).addPoints(pointsWon);
    }

    setState(() {
      _isSpinning = false;
    });

    // Show victory dialog if won
    if (pointsWon > 0 && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => GameVictoryDialog(
          gameName: 'Slot Machine',
          pointsWon: pointsWon,
          onViewPressed: () {
            // Navigate to wallet after dialog closes
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) context.go('/wallet');
            });
          },
          onClose: () {
            // Just close - no navigation needed
          },
        ),
      );
    }
  }

  Future<void> _animateReel(
      FixedExtentScrollController controller, int targetIndex, int durationMs) {
    final fullRotations = 5 + Random().nextInt(3);
    final targetPosition = (fullRotations * _symbols.length) + targetIndex;

    return controller.animateToItem(
      targetPosition,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final primaryColor = user.levelColor;
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
        statusMessage = gameAvailability.message ?? 'Ya jugaste hoy';
        statusColor = Colors.orange;
        break;
      case GameStatus.lockedTime:
        statusMessage = gameAvailability.message ?? 'No disponible ahora';
        statusColor = Colors.grey;
        break;
      case GameStatus.lockedMembership:
        statusMessage = gameAvailability.message ?? 'Nivel insuficiente';
        statusColor = Colors.purple;
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
