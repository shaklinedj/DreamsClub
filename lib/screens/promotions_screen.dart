import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCasinoId = ref.watch(activeCasinoIdProvider);

    if (activeCasinoId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Promociones')),
        body: const Center(
          child: Text('Selecciona un casino para ver sus promociones.'),
        ),
      );
    }

    final promotions = ref.watch(promotionsProvider(activeCasinoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promociones del Casino'),
      ),
      body: promotions.when(
        data: (List<Promotion> promotionList) {
          if (promotionList.isEmpty) {
            return const Center(
              child: Text('No hay promociones disponibles para este casino.'),
            );
          }
          return ListView.builder(
            itemCount: promotionList.length,
            itemBuilder: (context, index) {
              final promotion = promotionList[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(promotion.titulo),
                  subtitle: Text(promotion.descripcion),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
