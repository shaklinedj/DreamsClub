import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SelectFavoriteScreen extends ConsumerWidget {
  const SelectFavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCasinos = ref.watch(casinosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige tu Casino Favorito'),
        automaticallyImplyLeading: false, // No hay botón de regreso
      ),
      body: allCasinos.when(
        data: (List<Casino> casinos) => ListView.builder(
          itemCount: casinos.length,
          itemBuilder: (context, index) {
            final casino = casinos[index];
            return ListTile(
              title: Text(casino.nombre),
              subtitle: Text(casino.ciudad),
              onTap: () async {
                // Guardar como favorito y establecer como activo
                final navigator = GoRouter.of(context);
                await ref
                    .read(favoriteCasinoServiceProvider)
                    .setFavoriteCasinoId(casino.id);
                ref.read(activeCasinoIdProvider.notifier).state = casino.id;
                // Navegar a la pantalla principal
                navigator.go('/home');
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
