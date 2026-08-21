import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:casinoloyalty_flutter/services/daily_bonus_service.dart';
import 'package:casinoloyalty_flutter/services/coyhaique_location_service.dart';
import 'package:casinoloyalty_flutter/services/sound_service.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:casinoloyalty_flutter/screens/stickers_gallery_screen.dart';

class DailyBonusDialog extends ConsumerStatefulWidget {
  const DailyBonusDialog({super.key});

  @override
  ConsumerState<DailyBonusDialog> createState() => _DailyBonusDialogState();
}

class _DailyBonusDialogState extends ConsumerState<DailyBonusDialog> {
  late ConfettiController _confettiController;
  bool _isClaimed = false;
  bool _isCheckingLocation = false;
  String? _locationErrorMessage;
  bool _isGpsDisabled = false;
  String _rewardTitle = 'Pack de Stickers Dreams Coyhaique 🎨';
  String _rewardDesc = '¡Stickers exclusivos para WhatsApp desbloqueados por tu visita a Coyhaique!';

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _claimBonus() async {
    setState(() {
      _isCheckingLocation = true;
      _locationErrorMessage = null;
      _isGpsDisabled = false;
    });

    final result = await CoyhaiqueLocationService.checkCoyhaiqueLocation();

    setState(() {
      _isCheckingLocation = false;
    });

    if (result.serviceDisabled) {
      setState(() {
        _isGpsDisabled = true;
        _locationErrorMessage =
            '📍 El servicio de ubicación (GPS) está desactivado. Actívalo en la configuración de tu teléfono para verificar tu racha.';
      });
      return;
    }

    if (result.permissionDenied) {
      setState(() {
        _locationErrorMessage =
            '📍 Permiso de ubicación denegado. Se requieren permisos de GPS para verificar tu racha.';
      });
      return;
    }

    if (!result.isNear) {
      final distanceText = result.distanceKm != null
          ? 'a ${result.distanceKm!.toStringAsFixed(1)} km'
          : 'fuera del radio';

      setState(() {
        _locationErrorMessage =
            '📍 Te encuentras $distanceText de Dreams Coyhaique (Magallanes 131). Las rachas requieren estar en el casino presencialmente.';
      });
      return;
    }

    await _executeClaim();
  }

  Future<void> _executeClaim() async {
    await ref.read(dailyBonusProvider.notifier).claimBonus();
    final streak = ref.read(dailyBonusProvider).currentStreak;

    // Digital Rewards logic based on streak
    if (streak >= 7) {
      _rewardTitle = '🌟 Tema Dorado VIP + Pack Stickers Pro';
      _rewardDesc = '¡Racha legendaria de $streak días en Coyhaique! Acceso al tema Gold exclusivo y todos los stickers.';
    } else if (streak >= 3) {
      _rewardTitle = '🎨 Pack Stickers Animados Coyhaique';
      _rewardDesc = '¡Stickers con movimiento para compartir en WhatsApp con amigos!';
    } else {
      _rewardTitle = '🎁 Pack Stickers Oficiales Día $streak';
      _rewardDesc = '¡Stickers de la Patagonia y Dreams para tu WhatsApp!';
    }

    setState(() {
      _isClaimed = true;
      _locationErrorMessage = null;
    });
    _confettiController.play();
    SoundService.instance.playSuccess();
  }

  void _openStickers() {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StickersGalleryScreen()),
    );
  }

  Future<void> _shareStreak() async {
    final streak = ref.read(dailyBonusProvider).currentStreak;
    await SharePlus.instance.share(ShareParams(
      text:
          '🔥 ¡Llevo una racha de $streak días en Dreams Club Coyhaique y desbloqueé stickers exclusivos! 🎰✨ #DreamsClub #Coyhaique',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyBonusProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF161922), Color(0xFF232738)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🔥 RACHA DIARIA',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                if (!_isClaimed) ...[
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                    ),
                    child: const Center(
                      child: Text('🔥', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Racha actual: ${state.currentStreak} días!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entra cada día para desbloquear stickers de WhatsApp, temas y colores exclusivos para tu celular.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (_isCheckingLocation) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    const SizedBox(height: 12),
                    const Text(
                      'Verificando tu ubicación en Dreams Coyhaique... 📍',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ] else if (_locationErrorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _locationErrorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          if (_isGpsDisabled) ...[
                            ElevatedButton.icon(
                              onPressed: () => Geolocator.openLocationSettings(),
                              icon: const Icon(Icons.settings, size: 16, color: Colors.black),
                              label: const Text('Activar GPS en Ajustes', style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          TextButton.icon(
                            onPressed: _claimBonus,
                            icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                            label: const Text('Reintentar Verificación GPS', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _claimBonus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 36,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 6,
                      ),
                      child: const Text(
                        'CHECK-IN EN COYHAIQUE 📍',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFD4AF37),
                    size: 70,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _rewardTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rewardDesc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openStickers,
                    icon: const Icon(Icons.download, size: 20),
                    label: const Text('Descargar / Usar Stickers'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366), // WhatsApp green
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cerrar', style: TextStyle(color: Colors.white60)),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _shareStreak,
                        icon: const Icon(Icons.share, size: 16, color: Colors.blueAccent),
                        label: const Text('Compartir Racha', style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 40,
            gravity: 0.1,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Color(0xFFD4AF37),
            ],
          ),
        ),
      ],
    );
  }
}

