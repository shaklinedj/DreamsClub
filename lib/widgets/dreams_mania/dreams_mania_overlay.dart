import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/services/dreams_mania_service.dart';
import 'package:casinoloyalty_flutter/widgets/dreams_mania/falling_chip_widget.dart';
import 'package:casinoloyalty_flutter/widgets/dreams_mania/victory_card_dialog.dart';

class DreamsManiaOverlay extends ConsumerStatefulWidget {
  const DreamsManiaOverlay({super.key});

  @override
  ConsumerState<DreamsManiaOverlay> createState() => _DreamsManiaOverlayState();
}

class _DreamsManiaOverlayState extends ConsumerState<DreamsManiaOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _alarmController;
  late Animation<Color?> _alarmColorAnimation;
  final List<Widget> _fallingChips = [];
  Timer? _spawnerTimer;

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
  }

  @override
  void dispose() {
    _alarmController.dispose();
    _spawnerTimer?.cancel();
    super.dispose();
  }

  void _startSpawning() {
    _spawnerTimer?.cancel();
    _spawnerTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted) {
        setState(() {
          _fallingChips.add(
            FallingChipWidget(
              key: UniqueKey(), // Important for widget identity
              onCaught: () {
                ref
                    .read(dreamsManiaProvider.notifier)
                    .catchChip(1000); // $1000 per chip
                // Visual feedback or sound could go here
              },
            ),
          );
        });
      }
    });
  }

  void _stopSpawning() {
    _spawnerTimer?.cancel();
    setState(() {
      _fallingChips.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dreamsManiaProvider);

    // Listen to state changes to handle spawning and dialogs
    ref.listen(dreamsManiaProvider, (previous, next) {
      if (next.status == DreamsManiaStatus.active &&
          previous?.status != DreamsManiaStatus.active) {
        _startSpawning();
      } else if (next.status == DreamsManiaStatus.finished &&
          previous?.status != DreamsManiaStatus.finished) {
        _stopSpawning();
        _showVictoryDialog(next.score);
      }
    });

    if (state.status == DreamsManiaStatus.inactive) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 1. Alarm Phase (Flashing Background)
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
                          color: Colors.yellow, size: 80),
                      SizedBox(height: 20),
                      Text(
                        '¡ALERTA DE JACKPOT!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
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
                      SizedBox(height: 10),
                      Text(
                        'Prepárate para atrapar...',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // 2. Game Phase (Falling Chips + HUD)
        if (state.status == DreamsManiaStatus.active) ...[
          // Game Area (Transparent to allow seeing app behind, but catches taps?)
          // Actually we want to block interaction with app behind during game
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

          // Falling Chips
          ..._fallingChips,

          // HUD (Timer & Score)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      '${state.timeLeft}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(Icons.monetization_on, color: Color(0xFFD4AF37)),
                    const SizedBox(width: 8),
                    Text(
                      '\$${state.score}',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 24,
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
    );
  }

  void _showVictoryDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VictoryCardDialog(
        score: score,
        onShare: () {
          // TODO: Implement actual sharing
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
