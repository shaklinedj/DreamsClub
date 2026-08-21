import 'package:casinoloyalty_flutter/models/gamification_model.dart';
import 'package:casinoloyalty_flutter/providers/gamification_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/coyhaique_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GamificationSection extends ConsumerWidget {
  const GamificationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final localStreak = ref.watch(streakProvider);
    final longest = localStreak.longestStreak < user.streak ? user.streak : localStreak.longestStreak;

    final streakData = localStreak.copyWith(
      currentStreak: user.streak,
      longestStreak: longest,
      bonusMultiplier: (1.0 + (user.streak * 0.1)).toInt(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Streak Card (Boton Naranja Unificado)
        _StreakCard(streak: streakData),
        const SizedBox(height: 16),
        const _MiniAchievementsList(),
      ],
    );
  }


}

class _StreakCard extends ConsumerStatefulWidget {
  final StreakData streak;

  const _StreakCard({required this.streak});

  @override
  ConsumerState<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends ConsumerState<_StreakCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isLoading
                ? null
                : () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final result = await CoyhaiqueLocationService.checkCoyhaiqueLocation();

                      if (!mounted || !context.mounted) return;

                      if (result.serviceDisabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              '📍 El GPS (servicio de ubicación) está desactivado. Actívalo para verificar tu racha.',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 7),
                            action: SnackBarAction(
                              label: 'ACTIVAR',
                              textColor: Colors.yellow,
                              onPressed: () => Geolocator.openLocationSettings(),
                            ),
                          ),
                        );
                        return;
                      }

                      if (result.permissionDenied) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '📍 Permiso de ubicación denegado. Se requiere GPS para registrar tu racha.',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (!result.isNear) {
                        final distanceText = result.distanceKm != null
                            ? 'a ${result.distanceKm!.toStringAsFixed(1)} km'
                            : 'fuera del radio';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '📍 Te encuentras $distanceText de Dreams Coyhaique (Magallanes 131). Las rachas requieren estar en el casino presencialmente.',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                        return;
                      }

                      final achievementsNotifier = ref.read(achievementsProvider.notifier);
                      final success = await achievementsNotifier.registerCasinoVisit('4');
                      if (mounted && context.mounted) {
                        if (success) {
                          ref.read(streakProvider.notifier).registerVisit();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Visita registrada! 🎉 Tu racha ha aumentado.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ya registraste tu visita hoy. ¡Vuelve mañana!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Error en registro de racha: $e');
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error al verificar tu ubicación. Inténtalo de nuevo.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade700,
                    Colors.deepOrange.shade900,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🔥 Racha Actual',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${widget.streak.currentStreak}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6, left: 4),
                                  child: Text(
                                    'días',
                                    style: TextStyle(color: Colors.white70, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt, color: Colors.yellow, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'x${widget.streak.bonusMultiplier}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Récord: ${widget.streak.longestStreak} días',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      final dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                      final isCompleted = widget.streak.weekProgress[index];
                      final isToday = index == DateTime.now().weekday - 1;

                      return Column(
                        children: [
                          Text(
                            dayLabels[index],
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: isToday
                                  ? Border.all(color: Colors.yellow, width: 2)
                                  : null,
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check, color: Colors.deepOrange, size: 18)
                                  : null,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'TOCA AQUÍ PARA REGISTRAR TU VISITA',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 12),
                    Text(
                      'Verificando GPS...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniAchievementsList extends ConsumerWidget {
  const _MiniAchievementsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements = ref.watch(achievementsProvider);
    
    // Mostramos solo algunos para mantenerlo mínimo
    final displayAchievements = achievements.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recompensas & Logros',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayAchievements.length,
            itemBuilder: (context, index) {
              final achievement = displayAchievements[index];
              return Container(
                width: 56,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: achievement.isUnlocked ? Colors.orange.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: achievement.isUnlocked ? Colors.orange.withValues(alpha: 0.5) : Colors.transparent,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        achievement.icon,
                        style: TextStyle(
                          fontSize: 24,
                          color: achievement.isUnlocked ? Colors.white : Colors.white30,
                        ),
                      ),
                      if (!achievement.isUnlocked)
                        const Icon(Icons.lock, size: 10, color: Colors.white30),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

