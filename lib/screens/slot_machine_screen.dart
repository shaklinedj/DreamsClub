import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';

class SlotMachineScreen extends ConsumerStatefulWidget {
  const SlotMachineScreen({super.key});

  @override
  ConsumerState<SlotMachineScreen> createState() => _SlotMachineScreenState();
}

class _SlotMachineScreenState extends ConsumerState<SlotMachineScreen> {
  final LocationService _locationService = LocationService();
  bool _isCheckingLocation = false;
  bool _canPlay = false;
  String? _locationError;

  // Slot Machine State
  final List<String> _symbols = ['🍒', '🍋', '🍇', '💎', '7️⃣', '🔔'];
  late FixedExtentScrollController _controller1;
  late FixedExtentScrollController _controller2;
  late FixedExtentScrollController _controller3;
  bool _isSpinning = false;
  String _resultMessage = '';

  @override
  void initState() {
    super.initState();
    _controller1 = FixedExtentScrollController();
    _controller2 = FixedExtentScrollController();
    _controller3 = FixedExtentScrollController();
    _checkLocation();
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  Future<void> _checkLocation() async {
    setState(() {
      _isCheckingLocation = true;
      _locationError = null;
    });

    try {
      final hasPermission = await _locationService.hasLocationPermission();
      if (!hasPermission) {
        final granted = await _locationService.requestLocationPermission();
        if (!granted) {
          setState(() {
            _locationError = 'Se requiere permiso de ubicación para jugar.';
            _isCheckingLocation = false;
          });
          return;
        }
      }

      // Get REAL location - No simulation
      await _locationService.getCurrentLocation();

      setState(() {
        _canPlay = true;
        _isCheckingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationError = 'Error al verificar ubicación: $e';
        _isCheckingLocation = false;
      });
    }
  }

  void _spin() {
    if (_isSpinning || !_canPlay) return;

    setState(() {
      _isSpinning = true;
      _resultMessage = '';
    });

    // Randomize target indices
    final random = Random();
    final target1 =
        random.nextInt(_symbols.length) + 20; // Spin at least 20 items
    final target2 = random.nextInt(_symbols.length) + 20;
    final target3 = random.nextInt(_symbols.length) + 20;

    // Animate controllers
    _controller1.animateToItem(
      target1,
      duration: const Duration(seconds: 1),
      curve: Curves.easeOut,
    );

    _controller2.animateToItem(
      target2,
      duration: const Duration(seconds: 2),
      curve: Curves.easeOut,
    );

    _controller3
        .animateToItem(
      target3,
      duration: const Duration(seconds: 3),
      curve: Curves.easeOut,
    )
        .then((_) {
      setState(() {
        _isSpinning = false;
        _checkWin(target1, target2, target3);
      });
    });
  }

  void _checkWin(int i1, int i2, int i3) {
    final s1 = _symbols[i1 % _symbols.length];
    final s2 = _symbols[i2 % _symbols.length];
    final s3 = _symbols[i3 % _symbols.length];

    if (s1 == s2 && s2 == s3) {
      setState(() {
        _resultMessage = '¡JACKPOT! 🎉 Ganaste con $s1';
      });
    } else if (s1 == s2 || s2 == s3 || s1 == s3) {
      setState(() {
        _resultMessage = '¡Casi! Dos iguales. ¡Sigue intentando!';
      });
    } else {
      setState(() {
        _resultMessage = 'Suerte para la próxima.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final primaryColor = user.levelColor;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Dreams Logo
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'DREAMS',
                    style: TextStyle(
                      color: Color(0xFFD4AF37), // Gold color
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontFamily: 'Serif', // Or custom font if available
                    ),
                  ),
                  Text(
                    'CASINO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Slot Machine Display
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReel(_controller1),
                  Container(width: 2, color: Colors.grey[800]),
                  _buildReel(_controller2),
                  Container(width: 2, color: Colors.grey[800]),
                  _buildReel(_controller3),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Result Message
            Text(
              _resultMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Spacer(),

            // Status / Play Button
            if (_isCheckingLocation)
              const CircularProgressIndicator()
            else if (_locationError != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.location_off, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      _locationError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: _checkLocation,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: _isSpinning ? null : _spin,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSpinning ? Colors.grey : primaryColor,
                    boxShadow: [
                      if (!_isSpinning)
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),

            const SizedBox(height: 20),
            const Text(
              'JUGAR',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildReel(FixedExtentScrollController controller) {
    return SizedBox(
      width: 80,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 80,
        physics: const FixedExtentScrollPhysics(),
        childDelegate: ListWheelChildLoopingListDelegate(
          children: _symbols.map((symbol) {
            return Center(
              child: Text(
                symbol,
                style: const TextStyle(fontSize: 40),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
