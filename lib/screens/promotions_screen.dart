
import 'package:casinoloyalty_flutter/services/user_prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/promotions_provider.dart';
import 'package:casinoloyalty_flutter/widgets/promotion_card.dart';
import 'package:go_router/go_router.dart';

// Provider para obtener el ID del casino favorito de forma asíncrona
final favoriteCasinoIdProvider = FutureProvider<int?>((ref) async {
  return UserPreferences.getFavoriteCasino();
});

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escucha el provider que obtiene el ID del casino favorito
    final favoriteCasinoIdAsync = ref.watch(favoriteCasinoIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promociones'),
        centerTitle: true,
      ),
      // Usa el resultado del FutureProvider para construir la UI
      body: favoriteCasinoIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar preferencias: $err')),
        data: (casinoId) {
          // Si no hay un casino favorito, muestra un mensaje y un botón
          if (casinoId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No has seleccionado un casino favorito.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => context.go('/select-favorite'),
                      child: const Text('Seleccionar un casino'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Si hay un casino favorito, busca y muestra sus promociones
          final promotions = ref.watch(promotionsProvider(casinoId));
          return promotions.when(
            data: (promos) {
              if (promos.isEmpty) {
                return const Center(child: Text('No hay promociones disponibles para este casino.'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(promotionsProvider(casinoId).future),
                child: ListView.builder(
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    final promo = promos[index];
                    return PromotionCard(promotion: promo);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error al cargar promociones: $err')),
          );
        },
      ),
    );
  }
}
