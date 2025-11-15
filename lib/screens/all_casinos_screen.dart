import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/services/favorite_casino_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AllCasinosScreen extends ConsumerWidget {
  const AllCasinosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casinos = ref.watch(casinosProvider);
    final favoriteCasinoService = FavoriteCasinoService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos los Casinos'),
      ),
      body: casinos.when(
        data: (data) {
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final casino = data[index];
              return ListTile(
                title: Text(casino.nombre),
                subtitle: Text(casino.ciudad),
                onTap: () async {
                  await favoriteCasinoService.saveFavoriteCasino(casino.id);
                  if (!context.mounted) return;
                  context.go('/casinos');
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
