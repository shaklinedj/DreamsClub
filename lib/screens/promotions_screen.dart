import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/promotions_provider.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:casinoloyalty_flutter/widgets/favorite_casino_placeholder.dart';
import 'package:casinoloyalty_flutter/widgets/promotion_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCasinoAsync = ref.watch(selectedCasinoProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Promociones'),
        centerTitle: true,
      ),
      body: selectedCasinoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar casino: $err')),
        data: (casino) {
          if (casino == null) {
            return FavoriteCasinoPlaceholder(
              onSelect: () => context.go('/select-favorite'),
            );
          }

          final promotions = ref.watch(promotionsProvider(casino.id));
          return promotions.when(
            data: (promos) {
              if (promos.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('No hay promociones disponibles actualmente para ${casino.nombre}.'),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(promotionsProvider(casino.id).future),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: promos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
