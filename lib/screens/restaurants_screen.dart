import 'package:casinoloyalty_flutter/models/restaurante_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/restaurant_providers.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:casinoloyalty_flutter/widgets/favorite_casino_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RestaurantsScreen extends ConsumerWidget {
  const RestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCasinoAsync = ref.watch(selectedCasinoProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Restaurantes'),
      ),
      body: selectedCasinoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error al cargar casino: $err')),
        data: (casino) {
          if (casino == null) {
            return FavoriteCasinoPlaceholder(
              icon: Icons.restaurant_menu,
              message: 'Selecciona tu casino favorito para conocer sus restaurantes.',
              onSelect: () => context.go('/select-favorite'),
            );
          }

          final restaurants = ref.watch(restaurantsProvider(casino.id));
          return restaurants.when(
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('Por ahora ${casino.nombre} no tiene restaurantes publicados.'),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(restaurantsProvider(casino.id).future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final restaurant = items[index];
                    return _RestaurantTile(restaurant: restaurant);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error al cargar restaurantes: $err')),
          );
        },
      ),
    );
  }
}

class _RestaurantTile extends StatelessWidget {
  const _RestaurantTile({required this.restaurant});

  final Restaurante restaurant;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              restaurant.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.restaurant, size: 40),
              ),
            ),
          ),
          ListTile(
            title: Text(
              restaurant.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text(
              'Gastronomía exclusiva Dreams',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
