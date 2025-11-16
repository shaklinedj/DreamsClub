import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/models/hotel_model.dart';
import 'package:casinoloyalty_flutter/models/promotion_model.dart';
import 'package:casinoloyalty_flutter/models/restaurante_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart' show casinosProvider;
import 'package:casinoloyalty_flutter/providers/event_providers.dart';
import 'package:casinoloyalty_flutter/providers/promotions_provider.dart';
import 'package:casinoloyalty_flutter/providers/restaurant_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CasinoDetailScreen extends ConsumerWidget {
  final String casinoId;

  const CasinoDetailScreen({super.key, required this.casinoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int id = int.parse(casinoId);
    final casinoDetails = ref.watch(casinosProvider);

    return Scaffold(
      body: casinoDetails.when(
        data: (casinos) {
          final Casino casino;
          try {
            casino = casinos.firstWhere((c) => c.id == id);
          } catch (e) {
            return const Center(child: Text('Casino no encontrado.'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    casino.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      shadows: <Shadow>[
                        Shadow(
                            offset: Offset(0.0, 1.0),
                            blurRadius: 6.0,
                            color: Color.fromARGB(255, 0, 0, 0)),
                      ],
                    ),
                  ),
                  background: Image.network(
                    casino.imageUrl,
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
                      Text(
                        casino.ciudad,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),
                      if (casino.hotel != null)
                        _buildHotelSection(context, casino.hotel!),
                      const Divider(),
                      _buildSection<Restaurante>(
                        context,
                        title: 'Restaurantes',
                        provider: restaurantsProvider(id),
                        itemBuilder: (restaurante) => ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              restaurante.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.restaurant),
                            ),
                          ),
                          title: Text(restaurante.nombre,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        emptyMessage:
                            'No hay restaurantes disponibles en este momento.',
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildSection<Promotion>(
                        context,
                        title: 'Promociones',
                        provider: promotionsProvider(id),
                        itemBuilder: (promotion) => ListTile(
                          leading: Icon(Icons.local_offer,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(promotion.titulo,
                              style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text(promotion.descripcion),
                        ),
                        emptyMessage:
                            'No hay promociones disponibles en este momento.',
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      _buildSection<Event>(
                        context,
                        title: 'Eventos',
                        provider: eventsProvider(id),
                        itemBuilder: (event) => ListTile(
                          leading: Icon(Icons.event,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(event.titulo,
                              style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text(event.descripcion),
                        ),
                        emptyMessage:
                            'No hay eventos programados en este momento.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error al cargar el casino: $err')),
      ),
    );
  }

  Widget _buildHotelSection(BuildContext context, Hotel hotel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hotel', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Image.network(
                hotel.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.hotel, size: 50, color: Colors.grey),
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(hotel.nombre,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSection<T>(
    BuildContext context, {
    required String title,
    required ProviderListenable provider,
    required Widget Function(T item) itemBuilder,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Consumer(builder: (context, ref, child) {
          final asyncValue = ref.watch(provider as ProviderListenable<AsyncValue<List<T>>>);
          return asyncValue.when(
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text(emptyMessage)),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) => itemBuilder(items[index]),
                separatorBuilder: (context, index) => const Divider(height: 1),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        }),
      ],
    );
  }
}
