// import 'package:casinoloyalty_flutter/models/casino_model.dart';
// import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
// import 'package:casinoloyalty_flutter/providers/location_provider.dart';
// import 'package:casinoloyalty_flutter/providers/location_monitoring_provider.dart';
// import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/onboarding_service.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // final LocationService _locationService = LocationService();
  final OnboardingService _onboardingService = OnboardingService();
  String _statusMessage = 'Cargando...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start pulsing after initial entrance animation
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
      }
    });

    _initializeApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
    }
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 1));

    // Request notification permissions implicitly handled in first launch
    // or we can do a quick check here if needed, but better driven by flow.

    final isFirstLaunch = await _onboardingService.isFirstLaunch();

    if (isFirstLaunch) {
      await _handleFirstLaunch();
    } else {
      // Ensure notifications for existing users too if needed, but avoiding blockers
      try {
        final notifStatus = await Permission.notification.status
            .timeout(const Duration(seconds: 3));
        if (notifStatus.isDenied) {
          // On Android 13+ this shows the runtime prompt.
          await Permission.notification.request().timeout(
                const Duration(seconds: 6),
              );
        }
      } catch (e) {
        debugPrint('Notification permission check/request error: $e');
      }

      // Also check location permission for game geo-fencing
      try {
        final locationStatus = await Permission.locationWhenInUse.status
            .timeout(const Duration(seconds: 3));
        if (locationStatus.isDenied) {
          await Permission.locationWhenInUse.request().timeout(
                const Duration(seconds: 10),
              );
        }
      } catch (e) {
        debugPrint('Location permission check/request error: $e');
      }

      await _handleNormalLaunch();
    }
  }

  Future<void> _handleFirstLaunch() async {
    _updateStatus('Bienvenido a Dreams Club');
    await Future.delayed(const Duration(seconds: 1));

    // 1. Request Notification Permission
    _updateStatus('Configurando notificaciones...');
    try {
      await Permission.notification.request().timeout(
            const Duration(seconds: 6),
          );
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Request Location Permission (for game geo-fencing)
    _updateStatus('Configurando ubicación...');
    try {
      final locationStatus = await Permission.locationWhenInUse.status;
      if (locationStatus.isDenied) {
        await Permission.locationWhenInUse.request().timeout(
              const Duration(seconds: 10),
            );
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 500));

    await _onboardingService.completeFirstLaunch();

    if (mounted) {
      context.go('/select-favorite');
    }
  }

  Future<void> _handleNormalLaunch() async {
    final favoriteCasinoId = await UserProfileService().loadFavoriteCasinoId();

    if (favoriteCasinoId != null) {
      // User has a favorite casino, go directly to home
      // We no longer check GPS distance
      if (mounted) {
        context.go('/home');
      }
    } else {
      // No favorite casino set, manual selection
      if (mounted) {
        context.go('/select-favorite');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                Theme.of(context).primaryColor.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated circles background
              Positioned(
                top: -100,
                right: -100,
                child: _AnimatedCircle(
                  size: 300,
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  duration: const Duration(seconds: 3),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -150,
                child: _AnimatedCircle(
                  size: 400,
                  color: Colors.purple.withValues(alpha: 0.05),
                  duration: const Duration(seconds: 4),
                ),
              ),
              // Main content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo with Netflix-style pulse
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                      builder: (context, entranceValue, child) {
                        return AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final entranceOpacity =
                                entranceValue.clamp(0.0, 1.0).toDouble();
                            final scale = entranceValue < 1.0
                                ? entranceValue
                                : _pulseAnimation.value;

                            final safeScale = scale < 0 ? 0.0 : scale;

                            return Transform.scale(
                              scale: safeScale,
                              child: Opacity(
                                opacity: entranceOpacity,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(
                                              alpha:
                                                  0.3 * _pulseAnimation.value,
                                            ),
                                        blurRadius: 40 * _pulseAnimation.value,
                                        spreadRadius:
                                            10 * _pulseAnimation.value,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/images/logo-dreams.png',
                                    width: 200,
                                    height: 200,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    // Status message
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _statusMessage,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Bottom branding
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1000),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Column(
                        children: [
                          Text(
                            'DREAMS CLUB',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tu experiencia premium',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated circle widget for background
class _AnimatedCircle extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _AnimatedCircle({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  State<_AnimatedCircle> createState() => _AnimatedCircleState();
}

class _AnimatedCircleState extends State<_AnimatedCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_controller.value * 0.1),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
