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

    ref.listen<int?>(streakCelebrationTriggerProvider, (previous, streak) async {
      if (streak != null) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'streak_notified_$streak';
        if (prefs.getBool(key) == true) {
          ref.read(streakCelebrationTriggerProvider.notifier).state = null;
          return; // Milestone already notified, skip
        }
        await prefs.setBool(key, true);

        _controllerCenter.play();
        
        String title = '';
        String desc = '';
        String icon = '🔥';
        
        if (streak >= 14) {
          title = '¡Maestro de Coyhaique!';
          desc = 'Tema Especial Patagónico desbloqueado.';
          icon = '👑';
        } else if (streak >= 7) {
          title = '¡Leyenda Patagónica!';
          desc = 'Tema Platino Austral & Stickers VIP desbloqueados.';
          icon = '🏆';
        } else if (streak >= 3) {
          title = '¡Racha Austral!';
          desc = 'Tema Dorado VIP & Stickers Memes desbloqueados.';
          icon = '⭐';
        } else if (streak >= 1) {
          title = '¡Primera Racha!';
          desc = 'Pack de Stickers Patagónicos desbloqueados.';
          icon = '🏔️';
        }

        _showUnlockDialog(icon, title, '¡Alcanzaste $streak días de racha!', '🎁 $desc');
        
        ref.read(streakCelebrationTriggerProvider.notifier).state = null;
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

    // Clear any active snackbars first
    ScaffoldMessenger.of(navContext).clearSnackBars();

    ScaffoldMessenger.of(navContext).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E2230),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rewardDesc,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
