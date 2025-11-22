import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/services/user_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class DecisionScreen extends ConsumerStatefulWidget {
  const DecisionScreen({super.key});

  @override
  ConsumerState<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends ConsumerState<DecisionScreen> {
  @override
  void initState() {
    super.initState();
    _determineNextScreen();
  }

  Future<void> _determineNextScreen() async {
    await Future.delayed(const Duration(seconds: 2));

    final favoriteCasinoId = await UserPreferences.getFavoriteCasino();

    List<Casino> casinos = [];
    try {
      casinos = await ref.read(casinosProvider.future);
    } catch (_) {
      // Si falla la carga de casinos continuamos con la lógica básica.
    }

    final locationService = ref.read(locationServiceProvider);
    Position? position;

    try {
      // Esto pedirá permisos si no se tienen, cumpliendo con que "la pida la primera vez"
      position = await locationService.getCurrentLocation();
    } catch (error) {
      // Si el usuario deniega, continuamos sin ubicación silenciosamente o mostrando un snackbar discreto
      debugPrint('No se pudo obtener ubicación: $error');
    }

    if (!mounted) return;

    if (favoriteCasinoId != null) {
      final favoriteCasino = _findCasinoById(casinos, favoriteCasinoId);

      if (favoriteCasino != null && position != null) {
        final distanceKm = _distanceToCasinoKm(position, favoriteCasino);

        // Usamos 60km como umbral para sugerir cambio, igual que en las notificaciones
        if (distanceKm > 60) {
          final goToClosest = await _askUserForClosestCasino();
          if (!mounted) return;

          if (goToClosest == true && casinos.isNotEmpty) {
            final closest = _findClosestCasino(casinos, position);
            // Guardamos el nuevo favorito y el estado
            await UserPreferences.setFavoriteCasino(closest.id);
            ref.read(activeCasinoIdProvider.notifier).state = closest.id;

            if (!mounted) return;
            context.go('/all-casinos/${closest.id}');
            return;
          }
        }
      }

      // Guardamos el estado para que la Home no recalcule
      ref.read(activeCasinoIdProvider.notifier).state = favoriteCasinoId;
      context.go('/all-casinos/$favoriteCasinoId');
      return;
    }

    if (position != null && casinos.isNotEmpty) {
      final closest = _findClosestCasino(casinos, position);
      // Guardamos el estado para que la Home no recalcule
      ref.read(activeCasinoIdProvider.notifier).state = closest.id;
      context.go('/all-casinos/${closest.id}');
    } else {
      context.go('/select-favorite');
    }
  }

  Casino? _findCasinoById(List<Casino> casinos, int id) {
    for (final casino in casinos) {
      if (casino.id == id) {
        return casino;
      }
    }
    return null;
  }

  Future<bool?> _askUserForClosestCasino() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estás lejos de tu casino favorito'),
        content: const Text(
            '¿Quieres que te mostremos el casino más cercano a tu ubicación actual?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ir a mi favorito'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buscar cercanos'),
          ),
        ],
      ),
    );
  }

  Casino _findClosestCasino(List<Casino> casinos, Position position) {
    Casino closest = casinos.first;
    double minDistance = _distanceToCasinoKm(position, closest);

    for (final casino in casinos.skip(1)) {
      final distance = _distanceToCasinoKm(position, casino);
      if (distance < minDistance) {
        minDistance = distance;
        closest = casino;
      }
    }
    return closest;
  }

  double _distanceToCasinoKm(Position position, Casino casino) {
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      casino.latitud,
      casino.longitud,
    );
    return meters / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
