
import 'package:casinoloyalty_flutter/providers/promotions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class PromotionDetailScreen extends ConsumerWidget {
  final String promotionId;

  const PromotionDetailScreen({super.key, required this.promotionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int id = int.parse(promotionId);
    final promotionDetails = ref.watch(promotionDetailsProvider(id));

    return Scaffold(

      body: promotionDetails.when(
        data: (promo) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(promo.titulo, style: const TextStyle(shadows: [Shadow(blurRadius: 10.0)])),
                  background: Image.network(
                    promo.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/placeholder.jpg', 
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Sobre la promoción',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promo.descripcion,
                         style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 300), 
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
