import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:casinoloyalty_flutter/services/spin_wheel_service.dart';
import 'package:casinoloyalty_flutter/widgets/spin_wheel_widget.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpinWheelScreen extends ConsumerStatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  ConsumerState<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends ConsumerState<SpinWheelScreen> {
  final SpinWheelService _spinService = SpinWheelService();
  final PrizeService _prizeService = PrizeService();
  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

  bool _isSpinning = false;
  bool _isCheckingEligibility = true;
  SpinEligibility? _eligibility;

  @override
  void initState() {
    super.initState();
    _checkEligibility();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkEligibility() async {
    setState(() => _isCheckingEligibility = true);

    // Simulate delay for better UX
    await Future.delayed(const Duration(seconds: 1));

    final user = ref.read(userProvider);
    final eligibility = await _spinService.canPlayToday(user.points);

    if (mounted) {
      setState(() {
        _eligibility = eligibility;
        _isCheckingEligibility = false;
      });
    }
  }

  void _simulateLocation() {
    setState(() {
      _eligibility = SpinEligibility(
        canPlay: true,
        reason: '¡Ubicación simulada exitosa!',
        nearestCasino: Casino(
          id: 1,
          nombre: 'Casino Simulado',
          ciudad: 'Debug City',
          direccion: 'Debug St 123',
          latitud: 0,
          longitud: 0,
          imageUrl: 'assets/images/iqq.jpg',
          description: 'Casino para pruebas',
          features: [],
          rating: 5.0,
        ),
        distanceMeters: 10.0,
      );
    });
  }

  Future<void> _spin() async {
    if (_eligibility == null || !_eligibility!.canPlay) return;

    setState(() => _isSpinning = true);

    // This triggers the wheel animation
    // The wheel widget will call _onSpinComplete when done
  }

  void _onSpinComplete(Prize prize) async {
    if (!mounted) return;

    // Record that user played today
    await _spinService.recordSpinToday();

    // Note: Points will be deducted by the backend/service
    // For now, we'll just record the spin
    // TODO: Implement proper points deduction through user provider

    // Create and save the won prize
    final wonPrize = _spinService.createWonPrize(
      prize: prize,
      casinoId: _eligibility!.nearestCasino!.id,
    );
    await _prizeService.saveWonPrize(wonPrize);

    // Show confetti
    _confettiController.play();

    setState(() => _isSpinning = false);

    // Show result dialog
    if (mounted) {
      _showPrizeDialog(wonPrize);
    }
  }

  void _showPrizeDialog(WonPrize wonPrize) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 ¡FELICIDADES!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              wonPrize.prize.icon,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              wonPrize.prize.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              wonPrize.prize.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Válido por ${wonPrize.prize.daysValid} días',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'Expira: ${wonPrize.daysUntilExpiry}',
                    style:
                        const TextStyle(color: Color(0xFFD4AF37), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/my-prizes');
            },
            child: const Text(
              'VER MIS PREMIOS',
              style: TextStyle(color: Color(0xFFD4AF37)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('GENIAL'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruleta de Premios'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // GPS Status
                if (_isCheckingEligibility)
                  const CircularProgressIndicator(color: Color(0xFFD4AF37))
                else if (_eligibility != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _eligibility!.canPlay
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _eligibility!.canPlay ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _eligibility!.canPlay
                              ? Icons.check_circle
                              : Icons.error,
                          color:
                              _eligibility!.canPlay ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _eligibility!.reason,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (_eligibility!.nearestCasino != null)
                                Text(
                                  '${_eligibility!.nearestCasino!.nombre} (${_eligibility!.distanceText})',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed:
                          _isCheckingEligibility ? null : _checkEligibility,
                      icon: const Icon(Icons.refresh, color: Color(0xFFD4AF37)),
                      label: const Text(
                        'Actualizar Ubicación',
                        style: TextStyle(color: Color(0xFFD4AF37)),
                      ),
                    ),
                    // Debug button - only visible in debug mode
                    if (true) ...[
                      // Always show for now as requested for testing
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _simulateLocation,
                        icon: const Icon(Icons.bug_report, color: Colors.grey),
                        label: const Text(
                          'Simular GPS',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),

                // Wheel
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFFD4AF37), width: 2),
                  ),
                  child: Column(
                    children: [
                      // Pointer
                      const Icon(Icons.arrow_drop_down,
                          size: 40, color: Color(0xFFD4AF37)),

                      SpinWheelWidget(
                        prizes: mockPrizes,
                        isSpinning: _isSpinning,
                        onSpinComplete: _onSpinComplete,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Points cost
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Costo por giro:',
                          style: TextStyle(color: Colors.white)),
                      Text(
                        '${SpinWheelService.spinCostPoints} pts',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // User points
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tus puntos:',
                          style: TextStyle(color: Colors.white)),
                      Text(
                        '${user.points} pts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Spin button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_eligibility?.canPlay ?? false) && !_isSpinning
                        ? _spin
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isSpinning ? 'GIRANDO...' : '🎰 GIRAR RULETA',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // My prizes link
                TextButton(
                  onPressed: () => context.push('/my-prizes'),
                  child: const Text(
                    'Ver mis premios ganados',
                    style: TextStyle(color: Color(0xFFD4AF37)),
                  ),
                ),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Color(0xFFD4AF37),
                Colors.red,
                Colors.green,
                Colors.blue,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
