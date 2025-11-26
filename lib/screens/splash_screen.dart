import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/location_providers.dart';
import 'package:casinoloyalty_flutter/services/location_service.dart';
import 'package:casinoloyalty_flutter/services/onboarding_service.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final LocationService _locationService = LocationService();
  final OnboardingService _onboardingService = OnboardingService();
  String _statusMessage = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => _statusMessage = message);
    }
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 1));

    final isFirstLaunch = await _onboardingService.isFirstLaunch();

    if (isFirstLaunch) {
      await _handleFirstLaunch();
    } else {
      await _handleNormalLaunch();
    }
  }

  Future<void> _handleFirstLaunch() async {
    _updateStatus('Bienvenido a Dreams Club');
    await Future.delayed(const Duration(seconds: 1));

    try {
      _updateStatus('Solicitando permisos de ubicación...');
      final hasPermission = await _locationService.requestLocationPermission();

      if (!hasPermission) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return;
      }

      _updateStatus('Buscando casino más cercano...');
      await _findAndSetNearestCasino();

      await _onboardingService.completeFirstLaunch();
      await _onboardingService.completeLocationSetup();
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
            'No pudimos encontrar tu ubicación. Por favor selecciona un casino manualmente.');
      }
    }
  }

  Future<void> _handleNormalLaunch() async {
    final favoriteCasinoId = await UserProfileService().loadFavoriteCasinoId();

    if (favoriteCasinoId != null) {
      // User has a favorite casino, go directly to it
      if (mounted) {
        context.go('/home');
      }
    } else {
      // No favorite casino set, ask them to choose one
      if (mounted) {
        context.go('/select-favorite');
      }
    }
  }

  Future<void> _findAndSetNearestCasino() async {
    final casinos = await ref.read(casinosProvider.future);

    if (casinos.isEmpty) {
      if (mounted) {
        context.go('/select-favorite');
      }
      return;
    }

    final nearestCasino = await ref.read(nearestCasinoProvider(casinos).future);

    if (nearestCasino != null) {
      await UserProfileService().saveFavoriteCasinoId(nearestCasino.id);
      ref.read(activeCasinoIdProvider.notifier).state = nearestCasino.id;

      if (mounted) {
        context.go('/home');
      }
    } else {
      if (mounted) {
        context.go('/select-favorite');
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permisos necesarios'),
        content: const Text(
            'Necesitamos acceso a tu ubicación para encontrar el casino más cercano. '
            'Puedes seleccionar un casino manualmente si prefieres.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/select-favorite');
            },
            child: const Text('Seleccionar manualmente'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
              context.go('/select-favorite');
            },
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Aviso'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/select-favorite');
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo-dreams.png', width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
