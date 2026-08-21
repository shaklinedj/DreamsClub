import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:casinoloyalty_flutter/models/gamification_model.dart';
import 'package:casinoloyalty_flutter/providers/gamification_provider.dart';
import 'package:casinoloyalty_flutter/navigation/coyhaique_router.dart';

import 'package:shared_preferences/shared_preferences.dart';

class GlobalConfettiWidget extends ConsumerStatefulWidget {
  const GlobalConfettiWidget({super.key});

  @override
  ConsumerState<GlobalConfettiWidget> createState() =>
      _GlobalConfettiWidgetState();
}

class _GlobalConfettiWidgetState extends ConsumerState<GlobalConfettiWidget> {
  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    _controllerCenter =
        ConfettiController(duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _controllerCenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Achievement?>(confettiTriggerProvider, (previous, next) {
      if (next != null) {
        _controllerCenter.play();
        _showUnlockDialog(next.icon, '¡Nuevo Nivel Alcanzado!', 'Has desbloqueado: ${next.title}', '🎁 Recompensa: ${next.rewardDescription}');

        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            ref.read(confettiTriggerProvider.notifier).state = null;
          }
        });
      }
    });

    ref.listen<StreakData>(streakProvider, (previous, next) async {
      if (previous != null && next.currentStreak > previous.currentStreak) {
        if ([1, 3, 7, 14, 30].contains(next.currentStreak)) {
          final prefs = await SharedPreferences.getInstance();
          final key = 'streak_notified_${next.currentStreak}';
          if (prefs.getBool(key) == true) return; // Milestone already notified, skip
          await prefs.setBool(key, true);

          _controllerCenter.play();
          
          String title = '';
          String desc = '';
          String icon = '🔥';
          
          if (next.currentStreak >= 14) {
            title = '¡Maestro de Coyhaique!';
            desc = 'Tema Especial Patagónico desbloqueado.';
            icon = '👑';
          } else if (next.currentStreak >= 7) {
            title = '¡Leyenda Patagónica!';
            desc = 'Tema Platino Austral & Stickers VIP desbloqueados.';
            icon = '🏆';
          } else if (next.currentStreak >= 3) {
            title = '¡Racha Austral!';
            desc = 'Tema Dorado VIP & Stickers Memes desbloqueados.';
            icon = '⭐';
          } else if (next.currentStreak >= 1) {
            title = '¡Primera Racha!';
            desc = 'Pack de Stickers Patagónicos desbloqueados.';
            icon = '🏔️';
          }

          _showUnlockDialog(icon, title, '¡Alcanzaste ${next.currentStreak} días de racha!', '🎁 $desc');
        }
      }
    });

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _controllerCenter,
          blastDirection: pi / 2, // DOWN
          maxBlastForce: 20,
          minBlastForce: 5,
          emissionFrequency: 0.05,
          numberOfParticles: 30,
          gravity: 0.3,
          colors: const [
            Colors.green,
            Colors.blue,
            Colors.pink,
            Colors.orange,
            Colors.purple
          ],
        ),
      ),
    );
  }

  void _showUnlockDialog(String icon, String title, String subtitle, String rewardDesc) {
    final navContext = coyhaiqueRootNavigatorKey.currentContext;
    if (navContext == null) return;

    bool isClosed = false;

    showDialog(
      context: navContext,
      builder: (ctx) {
        // Auto dismiss dialog after 3.5 seconds so user doesn't have to manually click
        Future.delayed(const Duration(milliseconds: 3500), () {
          if (!isClosed && ctx.mounted && Navigator.of(ctx).canPop()) {
            isClosed = true;
            Navigator.of(ctx).pop();
          }
        });

        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Text(
                  rewardDesc,
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!isClosed) {
                  isClosed = true;
                  Navigator.of(ctx).pop();
                }
              },
              child:
                  const Text('¡Genial!', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
