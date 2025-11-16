
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/services/user_prefs.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart'; 
import 'package:casinoloyalty_flutter/screens/widgets/casino_card.dart';

class SelectFavoriteScreen extends ConsumerWidget {
  const SelectFavoriteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casinosAsync = ref.watch(casinosProvider);

    void handleSelectCasino(int casinoId) async {
      await UserPreferences.setFavoriteCasino(casinoId);
      
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Casino favorito guardado!')),
      );
      context.go('/home');
    }

    return Scaffold(
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
