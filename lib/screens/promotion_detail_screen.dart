
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:casinoloyalty_flutter/services/promotion_service.dart';

// Provider para el servicio de promociones
final promotionServiceProvider = Provider((ref) => PromotionService());

// Provider para obtener una promoción específica por su ID
final promotionDetailProvider = FutureProvider.family<Promotion, int>((ref, id) {
  return ref.watch(promotionServiceProvider).getPromotionById(id);
});

class PromotionDetailScreen extends ConsumerWidget {
  final String promotionId;

  const PromotionDetailScreen({super.key, required this.promotionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int id = int.parse(promotionId);
    final promotionAsyncValue = ref.watch(promotionDetailProvider(id));

    return Scaffold(
      body: promotionAsyncValue.when(
        data: (promotion) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
                title: Text(
                  promotion.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    shadows: <Shadow>[
                      Shadow(offset: Offset(0.0, 2.0), blurRadius: 8.0, color: Colors.black87),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                background: Image.network(
                  promotion.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child: const Center(
                        child: Icon(Icons.local_offer, color: Colors.white, size: 80),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Detalles de la Promoción',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).colorScheme.primary
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      promotion.descripcion,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
