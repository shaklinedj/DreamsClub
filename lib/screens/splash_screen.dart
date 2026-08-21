import 'package:casinoloyalty_flutter/services/onboarding_service.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  final OnboardingService _onboardingService = OnboardingService();
  String _statusMessage = 'Cargando...';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

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
    final isFirstLaunch = await _onboardingService.isFirstLaunch();

    if (isFirstLaunch) {
      await _handleFirstLaunch();
    } else {
      Permission.notification.status.then((status) {
        if (status.isDenied) {
          Permission.notification.request();
        }
      }).catchError((e) {
        debugPrint('Notification permission check error: $e');
      });

      await _handleNormalLaunch();
    }
  }

  Future<void> _handleFirstLaunch() async {
    _updateStatus('Bienvenido a Dreams Club Coyhaique');
    await UserProfileService().saveFavoriteCasinoId('4');
    await _onboardingService.completeFirstLaunch();

    if (mounted) {
      context.go('/feed');
    }
  }

  Future<void> _handleNormalLaunch() async {
    await UserProfileService().saveFavoriteCasinoId('4');

    if (mounted) {
      context.go('/feed');
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
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coyhaique',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.8),
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

class _AnimatedCircle extends StatelessWidget {
  final double size;
  final Color color;
  final Duration duration;

  const _AnimatedCircle({
    required this.size,
    required this.color,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
        );
      },
    );
  }
}
