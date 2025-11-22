import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/services/dreams_mania_service.dart';
import 'package:casinoloyalty_flutter/widgets/dreams_mania/victory_card_dialog.dart';

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
              // _audioPlayer.play(AssetSource('sounds/coin.mp3')); // TODO: Add sound asset
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

    final state = ref.watch(dreamsManiaProvider);

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
                        const Icon(Icons.monetization_on,
                            color: Color(0xFFD4AF37), size: 28),
                        const SizedBox(width: 10),
                        Text(
                          '\$${state.score}',
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

  void _showVictoryDialog() {
    final score = ref.read(dreamsManiaProvider).score;

    // Close current dialog first
    Navigator.of(context).pop();

    // Show victory dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VictoryCardDialog(
        score: score,
        onShare: () {
          Navigator.of(context).pop();
          ref.read(dreamsManiaProvider.notifier).reset();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Victoria compartida!')),
          );
        },
        onClose: () {
          Navigator.of(context).pop();
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
            onTap: widget.onCaught,
            child: Transform.rotate(
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
                    '\$',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 36,
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
