import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/models/farmland_model.dart';
import 'package:casinoloyalty_flutter/providers/farmland_provider.dart';

class FarmlandGameScreen extends ConsumerStatefulWidget {
  const FarmlandGameScreen({super.key});

  @override
  ConsumerState<FarmlandGameScreen> createState() => _FarmlandGameScreenState();
}

class _FarmlandGameScreenState extends ConsumerState<FarmlandGameScreen>
    with TickerProviderStateMixin {
  late AnimationController _wateringController;
  late AnimationController _sunRaysController;
  late AnimationController _cloudController;
  late AnimationController _windmillController;
  late AnimationController _plantBounceController;
  late AnimationController _animalIdleController;

  bool _isWatering = false;
  String? _animalSpeechBubble;
  Timer? _speechTimer;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();

    _wateringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _sunRaysController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    _windmillController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _plantBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animalIdleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _wateringController.dispose();
    _sunRaysController.dispose();
    _cloudController.dispose();
    _windmillController.dispose();
    _plantBounceController.dispose();
    _animalIdleController.dispose();
    _speechTimer?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  void _onWaterPressed() async {
    final farmland = ref.read(farmlandProvider);
    if (farmland.waterDrops < 10) {
      _showNoWaterSnackBar();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isWatering = true);
    _wateringController.forward(from: 0.0);

    final success = await ref.read(farmlandProvider.notifier).waterCrop();

    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() => _isWatering = false);
    }

    if (success) {
      HapticFeedback.lightImpact();
      final updatedFarmland = ref.read(farmlandProvider);
      if (updatedFarmland.cropProgress >= 100.0) {
        _showHarvestDialog();
      }
    }
  }

  void _onUseFertilizer() async {
    final farmland = ref.read(farmlandProvider);
    if (farmland.fertilizerCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.deepOrange.shade800,
          content: const Text(
            '¡No tienes fertilizante mágico! Cosecha o completa tareas para conseguirlo.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    final ok = await ref.read(farmlandProvider.notifier).useFertilizer();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          content: Text(
            '✨ ¡Fertilizante Mágico Aplicado! +5% de Crecimiento Inmediato 🌾',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
      final updated = ref.read(farmlandProvider);
      if (updated.cropProgress >= 100.0) {
        _showHarvestDialog();
      }
    }
  }

  void _onPetAnimal(String animalId, String sound, String name) async {
    HapticFeedback.selectionClick();
    final waterGained =
        await ref.read(farmlandProvider.notifier).petAnimal(animalId);

    _speechTimer?.cancel();
    setState(() {
      _animalSpeechBubble = waterGained > 0
          ? '$sound ¡Gracias! +$waterGained 💧'
          : '$sound (Ya descansé por hoy)';
    });

    _speechTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _animalSpeechBubble = null;
        });
      }
    });
  }

  void _showNoWaterSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Row(
          children: [
            Icon(Icons.water_drop_outlined, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '¡Sin agua suficiente! Reclama el cubo o completa tareas.',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'TAREAS',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFF1E293B),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.amber, width: 3),
                ),
                child: Text(
                  farmland.currentCropInfo.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '🌾 ¡COSECHA DORADA! 🌾',
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
                'Has cosechado con éxito tu ${farmland.cropType}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade700,
                      Colors.orange.shade800,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      '+${farmland.rewardPoints} Puntos Dreams',
                      style: const TextStyle(
                        color: Colors.white,
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
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(farmlandProvider.notifier).harvestCrop();
                },
                child: const Text(
                  '¡RECLAMAR Y SEMBRAR MÁS!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSeedSelectorModal() {
    final farmland = ref.read(farmlandProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF182234),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text('🌱 ', style: TextStyle(fontSize: 22)),
                  Text(
                    'Catálogo de Semillas Dreams',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona el cultivo que deseas sembrar en tu parcela:',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: kAvailableCrops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final crop = kAvailableCrops[idx];
                    final isSelected = crop.id == farmland.cropId;
                    final isUnlocked = farmland.level >= crop.requiredLevel;

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () async {
                              Navigator.pop(ctx);
                              await ref
                                  .read(farmlandProvider.notifier)
                                  .selectCrop(crop);
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? crop.primaryColor.withValues(alpha: 0.25)
                              : const Color(0xFF222F46),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? crop.primaryColor
                                : (isUnlocked
                                    ? Colors.white12
                                    : Colors.white10),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? crop.primaryColor.withValues(alpha: 0.2)
                                    : Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  isUnlocked ? crop.emoji : '🔒',
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    crop.name,
                                    style: TextStyle(
                                      color: isUnlocked
                                          ? Colors.white
                                          : Colors.white38,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isUnlocked
                                        ? crop.description
                                        : 'Requiere Nivel ${crop.requiredLevel}',
                                    style: TextStyle(
                                      color: isUnlocked
                                          ? Colors.white60
                                          : Colors.redAccent.shade100,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '+${crop.rewardPoints} Pts',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _openTasksModal() {
    final farmland = ref.read(farmlandProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF182234),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text('💧 ', style: TextStyle(fontSize: 22)),
                  Text(
                    'Misiones de Agua y Granja',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Consigue gotas de agua para acelerar tu cosecha:',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildTaskItem(
                title: 'Check-in Diario',
                reward: 50,
                icon: Icons.calendar_today_rounded,
                isCompleted: !farmland.canClaimDaily,
                onClaim: () =>
                    ref.read(farmlandProvider.notifier).claimDailyWater(),
              ),
              _buildTaskItem(
                title: 'Acaricia a los 4 animales de la granja',
                reward: 30,
                icon: Icons.pets_rounded,
                isCompleted: farmland.completedTasks['pet_all'] ?? false,
                onClaim: () => ref
                    .read(farmlandProvider.notifier)
                    .completeTask('pet_all', 30),
              ),
              _buildTaskItem(
                title: 'Visita Dreams Coyhaique',
                reward: 100,
                icon: Icons.casino_rounded,
                isCompleted: farmland.completedTasks['casino_visit'] ?? false,
                onClaim: () => ref
                    .read(farmlandProvider.notifier)
                    .completeTask('casino_visit', 100),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem({
    required String title,
    required int reward,
    required IconData icon,
    required bool isCompleted,
    required Future<void> Function() onClaim,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222F46),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isCompleted ? Colors.white10 : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.cyanAccent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                Text(
                  '+$reward Gotas de Agua 💧',
                  style:
                      const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isCompleted ? Colors.white12 : const Color(0xFF0284C7),
              foregroundColor: isCompleted ? Colors.white38 : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: isCompleted
                ? null
                : () async {
                    await onClaim();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
            child: Text(isCompleted ? 'Listo' : 'Reclamar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmland = ref.watch(farmlandProvider);
    final currentCrop = farmland.currentCropInfo;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF38BDF8), // Cielo azul diurno
              Color(0xFF60A5FA), // Horizonte celeste
              Color(0xFF86EFAC), // Pradera verde brillante
              Color(0xFF15803D), // Pasto verde bosque
            ],
            stops: [0.0, 0.3, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // ==========================================
              // 1. CAPA DE FONDO: CIELO, SOL, NUBES, MOLINO
              // ==========================================
              Positioned(
                top: 10,
                right: 20,
                child: AnimatedBuilder(
                  animation: _sunRaysController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _sunRaysController.value * 2 * math.pi,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.6),
                              blurRadius: 20,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Nubes flotantes animadas
              AnimatedBuilder(
                animation: _cloudController,
                builder: (context, child) {
                  final screenW = MediaQuery.of(context).size.width;
                  final xOffset =
                      (_cloudController.value * (screenW + 150)) - 80;
                  return Positioned(
                    top: 40,
                    left: xOffset % (screenW + 100) - 50,
                    child: Opacity(
                      opacity: 0.85,
                      child: Row(
                        children: [
                          Icon(Icons.cloud,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 48),
                          const SizedBox(width: 40),
                          Icon(Icons.cloud,
                              color: Colors.white.withValues(alpha: 0.7),
                              size: 36),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Colinas y Granero en el horizonte
              Positioned(
                top: 110,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 120,
                  child: Stack(
                    children: [
                      // Granero rústico (Izquierda)
                      Positioned(
                        left: 20,
                        bottom: 10,
                        child: _buildBarnWidget(),
                      ),
                      // Molino de viento con aspas animadas (Derecha)
                      Positioned(
                        right: 25,
                        bottom: 10,
                        child: _buildWindmillWidget(),
                      ),
                    ],
                  ),
                ),
              ),

              // ==========================================
              // 2. CONTENIDO PRINCIPAL SCROLLEABLE
              // ==========================================
              Column(
                children: [
                  // Barra Superior con Estado y Botón Salir
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        // Contador de Agua 💧
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.cyanAccent, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withValues(alpha: 0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop,
                                  color: Colors.cyanAccent, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                '${farmland.waterDrops}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Gotas',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        // Botón de Catálogo de Semillas
                        GestureDetector(
                          onTap: _openSeedSelectorModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: Colors.amber, width: 1.5),
                            ),
                            child: Row(
                              children: [
                                Text(currentCrop.emoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                const Text(
                                  'Semillas',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // 3. PARCELA DE CULTIVO VIVA Y ANIMALES
                  // ==========================================
                  Expanded(
                    child: Stack(
                      children: [
                        // Pasto y Valla
                        Positioned.fill(
                          top: 80,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A),
                                  Color(0xFF15803D),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Animales en el pasto
                        // 1. 🐄 Vaca Lola
                        Positioned(
                          top: 100,
                          left: 15,
                          child: _buildAnimalWidget(
                            id: 'cow',
                            name: 'Vaca Lola',
                            emoji: '🐄',
                            sound: '¡Muuuu!',
                            badge: '💧 +2',
                          ),
                        ),
                        // 2. 🐔 Gallina Clueca y pollitos
                        Positioned(
                          top: 105,
                          right: 25,
                          child: _buildAnimalWidget(
                            id: 'chicken',
                            name: 'Gallina',
                            emoji: '🐔🐣',
                            sound: '¡Cocorocó!',
                            badge: '💧 +2',
                          ),
                        ),
                        // 3. 🐑 Ovejita Austral
                        Positioned(
                          bottom: 120,
                          left: 18,
                          child: _buildAnimalWidget(
                            id: 'sheep',
                            name: 'Ovejita',
                            emoji: '🐑',
                            sound: '¡Beeeee!',
                            badge: '💧 +2',
                          ),
                        ),
                        // 4. 🐕 Perrito Guardián
                        Positioned(
                          bottom: 120,
                          right: 20,
                          child: _buildAnimalWidget(
                            id: 'dog',
                            name: 'Guardián',
                            emoji: '🐕',
                            sound: '¡Guau guau!',
                            badge: '💧 +2',
                          ),
                        ),

                        // Parcela Central de Cultivo (Tierra Arada 3D)
                        Center(
                          child: _buildCropPlotWidget(farmland, currentCrop),
                        ),

                        // Regadera Animada y Gotas de Lluvia
                        if (_isWatering)
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.22,
                            left: MediaQuery.of(context).size.width * 0.5 - 60,
                            child: _buildWateringAnimation(),
                          ),

                        // Burbuja de Diálogo de Animal
                        if (_animalSpeechBubble != null)
                          Positioned(
                            top: 60,
                            left: 40,
                            right: 40,
                            child:
                                _buildSpeechBubbleWidget(_animalSpeechBubble!),
                          ),
                      ],
                    ),
                  ),

                  // ==========================================
                  // 4. BARRA DE PROGRESO DE COSECHA
                  // ==========================================
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(currentCrop.emoji,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 8),
                                Text(
                                  currentCrop.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Nivel Granja ${farmland.level}',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Container(
                                height: 20,
                                color: Colors.white12,
                              ),
                              FractionallySizedBox(
                                widthFactor: (farmland.cropProgress / 100.0)
                                    .clamp(0.0, 1.0),
                                child: Container(
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF22C55E),
                                        Color(0xFFFDE047),
                                        Color(0xFFF59E0B),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso: ${farmland.cropProgress.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '+${currentCrop.rewardPoints} Pts al cosechar 🏆',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==========================================
                  // 5. ACCIONES PRINCIPALES (REGAR, CUBO, FERTILIZANTE)
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        // Cubo de Agua (Cada 3h)
                        Expanded(
                          flex: 3,
                          child: _buildBucketCollector(farmland),
                        ),
                        const SizedBox(width: 10),
                        // Fertilizante Mágico
                        Expanded(
                          flex: 3,
                          child: GestureDetector(
                            onTap: _onUseFertilizer,
                            child: Container(
                              height: 62,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFF6D28D9)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: Colors.purpleAccent, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('✨ Fertilizante',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                    '${farmland.fertilizerCount} disponibles',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // BOTÓN GIGANTE REGAR 💧
                        Expanded(
                          flex: 5,
                          child: GestureDetector(
                            onTap: _onWaterPressed,
                            child: Container(
                              height: 62,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0284C7),
                                    Color(0xFF0369A1)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.cyanAccent, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyan.withValues(alpha: 0.5),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.water_drop,
                                      color: Colors.white, size: 28),
                                  SizedBox(width: 6),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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

                  const SizedBox(height: 12),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SUB-WIDGETS DE ESCENARIO, ANIMALES Y CULTIVOS
  // =========================================================================

  Widget _buildCropPlotWidget(FarmlandState state, CropInfo crop) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: const Color(0xFF5B3A29), // Tierra arada fértil
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF8B5A2B), width: 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Surcos de tierra arada
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) => Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E2723),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Planta animada según etapa de crecimiento
          AnimatedBuilder(
            animation: _plantBounceController,
            builder: (context, child) {
              final scale = _isWatering
                  ? 1.25
                  : (1.0 + (_plantBounceController.value * 0.05));
              return Transform.scale(
                scale: scale,
                child: _buildPlantVisualStage(state.growthStage, crop),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlantVisualStage(int stage, CropInfo crop) {
    switch (stage) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3E2723),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8D6E63)),
              ),
              child: const Text('Semilla Plantada',
                  style: TextStyle(color: Colors.amber, fontSize: 11)),
            ),
          ],
        );
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Brote Tierno',
                  style:
                      TextStyle(color: Colors.lightGreenAccent, fontSize: 11)),
            ),
          ],
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪴', style: TextStyle(fontSize: 78)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Planta en Crecimiento',
                  style:
                      TextStyle(color: Colors.lightGreenAccent, fontSize: 11)),
            ),
          ],
        );
      case 3:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌸🌾', style: TextStyle(fontSize: 84)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Floración Madura',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ],
        );
      default: // Cosecha lista
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(crop.emoji, style: const TextStyle(fontSize: 96)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                '✨ ¡COSECHA LISTA! ✨',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 12),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAnimalWidget({
    required String id,
    required String name,
    required String emoji,
    required String sound,
    required String badge,
  }) {
    return GestureDetector(
      onTap: () => _onPetAnimal(id, sound, name),
      child: AnimatedBuilder(
        animation: _animalIdleController,
        builder: (context, child) {
          final dy = (id == 'chicken' || id == 'dog')
              ? _animalIdleController.value * 4
              : _animalIdleController.value * 2;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpeechBubbleWidget(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildWateringAnimation() {
    return Column(
      children: [
        Transform.rotate(
          angle: -math.pi / 6,
          child: const Icon(
            Icons.shower_rounded,
            color: Colors.cyanAccent,
            size: 54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop, color: Colors.cyan.shade200, size: 20),
            Icon(Icons.water_drop, color: Colors.cyanAccent, size: 28),
            Icon(Icons.water_drop, color: Colors.cyan.shade200, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildBucketCollector(FarmlandState farmland) {
    final canClaim = farmland.canClaimBucket;
    final remaining = farmland.bucketTimeRemaining;

    return GestureDetector(
      onTap: canClaim
          ? () => ref.read(farmlandProvider.notifier).claimBucketWater()
          : null,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: canClaim ? const Color(0xFF0D9488) : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: canClaim ? Colors.tealAccent : Colors.white24,
            width: canClaim ? 2 : 1,
          ),
          boxShadow: canClaim
              ? [
                  BoxShadow(
                      color: Colors.teal.withValues(alpha: 0.4), blurRadius: 8)
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              canClaim ? '🪣 ¡Cubo Listo!' : '🪣 Cubo Agua',
              style: TextStyle(
                color: canClaim ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              canClaim
                  ? '+20 Gotas'
                  : '${remaining.inHours.toString().padLeft(2, '0')}:${(remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                color: canClaim ? Colors.tealAccent : Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarnWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFB91C1C), // Rojo granero
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Row(
        children: [
          Text('🏡 ', style: TextStyle(fontSize: 18)),
          Text(
            'Granero',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWindmillWidget() {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _windmillController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _windmillController.value * 2 * math.pi,
              child: const Icon(Icons.autorenew_rounded,
                  color: Colors.white, size: 28),
            );
          },
        ),
        const SizedBox(width: 4),
        const Text('🌾 Molino',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ],
    );
  }
}
