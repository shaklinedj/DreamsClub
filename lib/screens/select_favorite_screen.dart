import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/screens/widgets/casino_card.dart';
import 'package:casinoloyalty_flutter/services/user_profile_service.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SelectFavoriteScreen extends ConsumerWidget {
  const SelectFavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casinosAsync = ref.watch(casinosProvider);

    Future<void> handleSelectCasino(int casinoId) async {
      await UserProfileService().saveFavoriteCasinoId(casinoId);
      ref.read(activeCasinoIdProvider.notifier).state = casinoId;
      ref.invalidate(selectedCasinoIdProvider);
      ref.invalidate(selectedCasinoProvider);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Casino favorito guardado!')),
      );
      // Redirigir a la pantalla de detalle del casino seleccionado
      context.go('/all-casinos/$casinoId');
    }

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Elige tu casino favorito'),
      ),
      body: casinosAsync.when(
        data: (casinos) => ListView.builder(
          itemCount: casinos.length,
          itemBuilder: (context, index) {
            final casino = casinos[index];
            return CasinoCard(
              casino: casino,
              onTap: () => handleSelectCasino(casino.id),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
