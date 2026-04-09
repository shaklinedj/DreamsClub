import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';

/// Screen shown when biometric authentication is required
/// Features a slot machine animation theme
class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isSpinning = true;
  bool _isAuthenticating = false;

  // Slot reel symbols
  final List<String> _symbols = ['🎲', '💎', '⭐', '🎰', '🏆', '7️⃣', 'ENTRAR'];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // Setup spinning animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isSpinning) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _symbols.length;
        });
        _controller.reset();
        _controller.forward();
      }
    });

    // Start spinning
    _controller.forward();

    // Stop after 2.5 seconds on "ENTRAR"
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _currentIndex = _symbols.length - 1; // Stop on "ENTRAR"
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || _isSpinning) return;

    setState(() => _isAuthenticating = true);

    final success =
        await ref.read(authProvider.notifier).authenticateWithBiometric();

    if (!mounted) return;

    setState(() => _isAuthenticating = false);

    if (success) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Dreams Logo
                Image.asset(
                  'assets/images/logo-dreams.png',
                  width: 180,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 50),

                // Slot Machine Reel
                GestureDetector(
                  onTap: _authenticate,
                  child: Container(
                    width: 220,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.amber.shade800,
                          Colors.amber.shade600,
                          Colors.amber.shade800,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.shade300,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orangeAccent.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0,
                                    _isSpinning ? -_animation.value * 20 : 0),
                                child: Text(
                                  _symbols[_currentIndex],
                                  style: TextStyle(
                                    fontSize:
                                        _symbols[_currentIndex] == 'ENTRAR'
                                            ? 32
                                            : 48,
                                    fontWeight: FontWeight.bold,
                                    color: _symbols[_currentIndex] == 'ENTRAR'
                                        ? Colors.amber
                                        : Colors.white,
                                    shadows: [
                                      Shadow(
                                        color:
                                            Colors.amber.withValues(alpha: 0.8),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Instruction text
                AnimatedOpacity(
                  opacity: _isSpinning ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isSpinning
                        ? 'Girando...'
                        : (_isAuthenticating
                            ? 'Verificando...'
                            : 'Toca para desbloquear'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Fingerprint icon hint
                if (!_isSpinning && !_isAuthenticating)
                  Icon(
                    Icons.fingerprint,
                    size: 40,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
