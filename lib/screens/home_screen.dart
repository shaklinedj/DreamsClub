import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/screens/casino_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCasinoId = ref.watch(activeCasinoIdProvider);

    if (activeCasinoId == null) {
      // Muestra un loader mientras se determina el casino
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Muestra los detalles del casino activo
    // Usamos una clave para asegurar que el widget se reconstruya si el ID cambia
    return CasinoDetailScreen(key: ValueKey(activeCasinoId), casinoId: activeCasinoId.toString());
  }
}
