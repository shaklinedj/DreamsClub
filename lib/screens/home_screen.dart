import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearestCasino = ref.watch(nearestCasinoProvider);

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo-dreams.png',
          height: 40,
        ),
        centerTitle: true,
      ),
      body: nearestCasino.when(
        data: (casino) {
          return Column(
            children: [
              SizedBox(
                height: 300,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(casino.latitud, casino.longitud),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId(casino.nombre),
                      position: LatLng(casino.latitud, casino.longitud),
                    ),
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      casino.nombre,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(casino.direccion),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se pudo obtener la ubicación.'),
              ElevatedButton(
                onPressed: () {
                  context.go('/all-casinos');
                },
                child: const Text('Elegir un casino'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
