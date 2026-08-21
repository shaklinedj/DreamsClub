import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/services/dreams_mania_service.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:casinoloyalty_flutter/services/spin_wheel_service.dart';
import 'package:casinoloyalty_flutter/widgets/game_victory_dialog.dart';
import 'package:go_router/go_router.dart';

class DreamsManiaDialog extends ConsumerStatefulWidget {
  const DreamsManiaDialog({super.key});

  @override
  ConsumerState<DreamsManiaDialog> createState() => _DreamsManiaDialogState();
}

class _DreamsManiaDialogState extends ConsumerState<DreamsManiaDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _alarmController;
  late Animation<Color?> _alarmColorAnimation;
  final List<_FallingChip> _fallingChips = [];
  Timer? _spawnerTimer;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _alarmController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _alarmColorAnimation = ColorTween(
      begin: Colors.red.withValues(alpha: 0.0),
      end: Colors.red.withValues(alpha: 0.5),
    ).animate(_alarmController);

    // Auto-close after alarm phase
    _autoCloseTimer = Timer(const Duration(seconds: 3), () {
      ref.read(dreamsManiaProvider.notifier);
      // Alarm phase ends, game starts automatically via service
    });
  }

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _alarmController.dispose();
    _spawnerTimer?.cancel();
    _autoCloseTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startSpawning() {
    if (_spawnerTimer != null) return;
    _spawnerTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          final random = Random();
          _fallingChips.add(_FallingChip(
            key: UniqueKey(),
            startX: random.nextDouble(),
            onCaught: () {
              ref.read(dreamsManiaProvider.notifier).catchChip(1000);
              _audioPlayer.play(AssetSource('sounds/coins.wav'));
              // Chip will be removed automatically when animation completes
            },
          ));
        });
      }
    });
  }

  void _stopSpawning() {
    _spawnerTimer?.cancel();
    _spawnerTimer = null;
    if (mounted) {
      setState(() {
        _fallingChips.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dreamsManiaProvider);

    // Start spawning if already active when dialog opens
    if (state.status == DreamsManiaStatus.active && _spawnerTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSpawning();
      });
    }

    ref.listen<DreamsManiaState>(dreamsManiaProvider, (previous, next) {
      if (previous == null) return;

      if (next.status == DreamsManiaStatus.active &&
          previous.status != DreamsManiaStatus.active) {
        _startSpawning();
      } else if (next.status == DreamsManiaStatus.finished &&
          previous.status != DreamsManiaStatus.finished) {
        _stopSpawning();
        _showVictoryDialog();
      }
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Stack(
          children: [
            // Alarm Phase
            if (state.status == DreamsManiaStatus.warning)
              AnimatedBuilder(
                animation: _alarmColorAnimation,
                builder: (context, child) {
                  return Container(
                    color: _alarmColorAnimation.value,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.yellow, size: 100),
                          SizedBox(height: 30),
                          Text(
                            '¡ALERTA DE JACKPOT!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black,
                                  offset: Offset(2.0, 2.0),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Prepárate para atrapar...',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Game Phase
            if (state.status == DreamsManiaStatus.active) ...[
              Container(
                color: Colors.black.withValues(alpha: 0.4),
              ),
              ..._fallingChips,
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(40),
                      border:
                          Border.all(color: const Color(0xFFD4AF37), width: 3),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '${state.timeLeft}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 30),
                        const Icon(Icons.stars,
                            color: Color(0xFFD4AF37), size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '${state.score} PTS',
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showVictoryDialog() async {
    final score = ref.read(dreamsManiaProvider).score;
    final prizeService = PrizeService();
    final spinWheelService = SpinWheelService();
    final user = ref.read(userProvider);
    final locationState = ref.read(locationProvider);
    final casinoId = locationState.nearestCasino?.id ?? '4';

    WonPrize? wonPrize;
    try {
      final catalog = await prizeService.getPrizesCatalog();
      if (catalog.isNotEmpty) {
        final random = Random();
        final selectedPrize = catalog[random.nextInt(catalog.length)];
        wonPrize = spinWheelService.createWonPrize(
          prize: selectedPrize,
          casinoId: casinoId,
          userId: user.email.isNotEmpty ? user.email : (user.rut ?? ''),
          userName: user.name,
          userEmail: user.email,
          userRut: user.rut ?? '',
          gameSource: 'dreams_mania',
        );
        await prizeService.saveWonPrize(wonPrize);
      }
    } catch (_) {}

    // Close current DreamsMania dialog first
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Play win sound
    try {
      await _audioPlayer.play(AssetSource('sounds/win.wav'));
    } catch (_) {}

    if (!mounted) return;

    // Show victory dialog with code
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => GameVictoryDialog(
        gameName: 'Dreams Mania',
        pointsWon: wonPrize == null ? score : null,
        prizeName: wonPrize?.prize.name,
        prizeIcon: wonPrize?.prize.icon,
        redemptionCode: wonPrize?.redemptionCode,
        viewButtonLabel: wonPrize != null ? 'VER EN MIS PREMIOS' : null,
        onViewPressed: () {
          ref.read(dreamsManiaProvider.notifier).reset();
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              if (wonPrize != null) {
                context.push('/my-prizes');
              } else {
                context.go('/wallet');
              }
            }
          });
        },
        onClose: () {
          ref.read(dreamsManiaProvider.notifier).reset();
        },
      ),
    );
  }
}

class _FallingChip extends StatefulWidget {
  final double startX;
  final VoidCallback onCaught;

  const _FallingChip({
    required super.key,
    required this.startX,
    required this.onCaught,
  });

  @override
  State<_FallingChip> createState() => _FallingChipState();
}

class _FallingChipState extends State<_FallingChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _rotation;
  bool _isCaught = false;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _rotation = random.nextDouble() * 2 * pi;

    _controller = AnimationController(
      duration: Duration(milliseconds: 2000 + random.nextInt(1000)),
      vsync: this,
    );

    _animation = Tween<double>(begin: -100, end: 1000).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Chip reached bottom without being caught
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: _animation.value,
          left: widget.startX * (screenWidth - 70),
          child: GestureDetector(
            onTap: () {
              if (_isCaught) return;
              setState(() {
                _isCaught = true;
              });
              HapticFeedback.heavyImpact();
              widget.onCaught();
            },
            child: _isCaught
                ? Container(
                    width: 70,
                    height: 70,
                    alignment: Alignment.center,
                    child: const Text(
                      '+1000',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                      ),
                    ),
                  )
                : Transform.rotate(
                    angle: _rotation + _controller.value * 4 * pi,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'PTS',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
