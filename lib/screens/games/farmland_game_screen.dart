import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/providers/farmland_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

class FarmlandGameScreen extends ConsumerStatefulWidget {
  const FarmlandGameScreen({super.key});

  @override
  ConsumerState<FarmlandGameScreen> createState() => _FarmlandGameScreenState();
}

class _FarmlandGameScreenState extends ConsumerState<FarmlandGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waterAnimController;
  bool _isWatering = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _waterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Timer para refrescar el temporizador del cubo de agua
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _waterAnimController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onWaterPressed() async {
    final farmland = ref.read(farmlandProvider);
    if (farmland.waterDrops < 10) {
      _showNoWaterSnackBar();
      return;
    }

    setState(() => _isWatering = true);
    _waterAnimController.forward(from: 0.0);

    final success =
        await ref.read(farmlandProvider.notifier).waterCrop();

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() => _isWatering = false);
    }

    if (success) {
      final updatedFarmland = ref.read(farmlandProvider);
      if (updatedFarmland.cropProgress >= 100.0) {
        _showHarvestDialog();
      }
    }
  }

  void _showNoWaterSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.shade700,
        content: const Row(
          children: [
            Icon(Icons.water_drop_outlined, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡No tienes suficiente agua! Completa misiones o reclama el cubo.',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'MISIONES',
          textColor: Colors.amberAccent,
          onPressed: () => _openTasksModal(),
        ),
      ),
    );
  }

  void _showHarvestDialog() {
    final farmland = ref.read(farmlandProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1E293B),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 72),
              const SizedBox(height: 12),
              const Text(
                '¡COSECHA COMPLETADA!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Has cultivado con éxito tu ${farmland.cropType}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      '+${farmland.rewardPoints} Puntos Dreams',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent.shade700,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(farmlandProvider.notifier).harvestCrop();
                },
                child: const Text(
                  '¡COSECHAR Y CONTINUAR!',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openTasksModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _FarmlandTasksModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmland = ref.watch(farmlandProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const Text(
                      'LA GRANJA DREAMS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    // User Points Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade600, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${user.points}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Water Drops Indicator & Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.cyanAccent, size: 32),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gotas de Agua',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            '${farmland.waterDrops} Gotas',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: _openTasksModal,
                        icon: const Icon(Icons.add_task, size: 18),
                        label: const Text(
                          'MISIONES',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Main Crop Growth Field Area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF065F46)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Soil Graphic Pattern
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3F2E21),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF5A4332), width: 4),
                            ),
                          ),
                        ),

                        // Crop Info Top Overlay
                        Positioned(
                          top: 28,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.shade300, width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Cultivo: ${farmland.cropType} (${farmland.rewardPoints} Pts)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Crop Growth Visual Icon / Animation
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 30),
                            AnimatedScale(
                              scale: _isWatering ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: _buildCropVisualWidget(farmland.growthStage),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getCropStageTitle(farmland.growthStage),
                              style: TextStyle(
                                color: Colors.greenAccent.shade100,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Watering Animation Overlay
                        if (_isWatering)
                          Positioned(
                            top: 90,
                            right: 70,
                            child: RotationTransition(
                              turns: Tween(begin: 0.0, end: -0.1).animate(_waterAnimController),
                              child: const Icon(
                                Icons.water_drop_rounded,
                                color: Colors.cyanAccent,
                                size: 54,
                              ),
                            ),
                          ),

                        // Progress Bar Bottom Overlay
                        Positioned(
                          bottom: 24,
                          left: 24,
                          right: 24,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progreso: ${farmland.cropProgress.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Nivel ${farmland.level}',
                                    style: const TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: farmland.cropProgress / 100.0,
                                  minHeight: 16,
                                  backgroundColor: Colors.black45,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.lightGreenAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action Buttons Row (Regar + Cubo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // Water Bucket Timer Collector
                    Expanded(
                      flex: 4,
                      child: _buildBucketWidget(context, ref, farmland),
                    ),
                    const SizedBox(width: 12),
                    // Giant WATER Button (-10 Drops)
                    Expanded(
                      flex: 6,
                      child: GestureDetector(
                        onTap: _onWaterPressed,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withValues(alpha: 0.5),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: Colors.cyanAccent, width: 2),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.water_drop, color: Colors.white, size: 28),
                              SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'REGAR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  Text(
                                    '-10 Gotas',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropVisualWidget(int stage) {
    IconData icon;
    Color color;
    double size = 90;

    switch (stage) {
      case 0:
        icon = Icons.grass;
        color = Colors.brown.shade300;
        size = 60;
        break;
      case 1:
        icon = Icons.eco;
        color = Colors.lightGreenAccent;
        size = 75;
        break;
      case 2:
        icon = Icons.nature;
        color = Colors.greenAccent;
        size = 90;
        break;
      case 3:
        icon = Icons.agriculture;
        color = Colors.amberAccent;
        size = 100;
        break;
      case 4:
      default:
        icon = Icons.stars_rounded;
        color = Colors.amber;
        size = 110;
        break;
    }

    return Container(
      width: size + 40,
      height: size + 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size),
    );
  }

  String _getCropStageTitle(int stage) {
    switch (stage) {
      case 0:
        return '🌱 Semilla recién plantada';
      case 1:
        return '🌿 ¡Brote germinando!';
      case 2:
        return '🌾 Creciendo fuerte';
      case 3:
        return '🌟 ¡Cultivo casi maduro!';
      case 4:
      default:
        return '🎉 ¡LISTO PARA COSECHAR!';
    }
  }

  Widget _buildBucketWidget(
      BuildContext context, WidgetRef ref, dynamic farmland) {
    final canClaim = farmland.canClaimBucket;
    final remaining = farmland.bucketTimeRemaining;

    String timerText = 'DISPONIBLE';
    if (!canClaim) {
      final h = remaining.inHours.toString().padLeft(2, '0');
      final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
      final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      timerText = '$h:$m:$s';
    }

    return GestureDetector(
      onTap: canClaim
          ? () async {
              final success = await ref
                  .read(farmlandProvider.notifier)
                  .claimBucketWater();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Reclamaste +20 Gotas del cubo de agua! 💧'),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            }
          : null,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: canClaim ? Colors.teal.shade700 : Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canClaim ? Colors.tealAccent : Colors.grey.shade700,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_drink,
                  color: canClaim ? Colors.tealAccent : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  canClaim ? '+20 Gotas' : 'Cubo de Agua',
                  style: TextStyle(
                    color: canClaim ? Colors.white : Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              timerText,
              style: TextStyle(
                color: canClaim ? Colors.tealAccent : Colors.amber,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmlandTasksModal extends ConsumerWidget {
  const _FarmlandTasksModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmland = ref.watch(farmlandProvider);
    final notifier = ref.read(farmlandProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_task, color: Colors.cyanAccent, size: 28),
              const SizedBox(width: 12),
              const Text(
                'MISIONES DE AGUA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily Check-in Task
          _TaskTile(
            title: 'Check-in Diario',
            subtitle: 'Entra a la granja cada día',
            reward: '+50 💧',
            isCompleted: !farmland.canClaimDaily,
            onClaim: () async {
              final ok = await notifier.claimDailyWater();
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Check-in reclamado (+50 Gotas)! 💧')),
                );
              }
            },
          ),
          const SizedBox(height: 10),

          // Visit Benefits Task
          _TaskTile(
            title: 'Explorar Beneficios',
            subtitle: 'Visita los convenios del club',
            reward: '+20 💧',
            isCompleted: farmland.completedTasks['visit_benefits'] == true,
            onClaim: () async {
              await notifier.completeTask('visit_benefits', 20);
              if (context.mounted) {
                Navigator.pop(context);
                context.push('/benefits');
              }
            },
          ),
          const SizedBox(height: 10),

          // Play Match Game Task
          _TaskTile(
            title: 'Jugar Dreams Match',
            subtitle: 'Combina gemas en el mini-juego',
            reward: '+30 💧',
            isCompleted: farmland.completedTasks['play_match'] == true,
            onClaim: () async {
              await notifier.completeTask('play_match', 30);
              if (context.mounted) {
                Navigator.pop(context);
                context.push('/match-game');
              }
            },
          ),
          const SizedBox(height: 10),

          // Spin Wheel Task
          _TaskTile(
            title: 'Girar Ruleta de la Suerte',
            subtitle: 'Prueba tu suerte diaria',
            reward: '+30 💧',
            isCompleted: farmland.completedTasks['play_roulette'] == true,
            onClaim: () async {
              await notifier.completeTask('play_roulette', 30);
              if (context.mounted) {
                Navigator.pop(context);
                context.push('/spin-wheel');
              }
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String reward;
  final bool isCompleted;
  final VoidCallback onClaim;

  const _TaskTile({
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.isCompleted,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.white10 : Colors.black38,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade800 : Colors.cyanAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isCompleted ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isCompleted ? Colors.grey : Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.grey.shade800 : Colors.cyanAccent,
              foregroundColor: isCompleted ? Colors.grey : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isCompleted ? null : onClaim,
            child: Text(
              isCompleted ? 'LISTO' : reward,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
