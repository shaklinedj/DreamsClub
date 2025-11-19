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
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

          return SingleChildScrollView(
            child: Column(
              children: [
                 SizedBox(
                  height: 250.0,
                  width: double.infinity,
                  child: Image.asset(
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        casino.nombre,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                       Text(
                        casino.ciudad,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openMaps(context, casino),
                          icon: const Icon(Icons.map),
                          label: const Text('Cómo llegar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (casino.hotel != null)
                        _buildHotelSection(context, casino.hotel!),
                      if (casino.hotel != null) const Divider(height: 32),
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
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          onTap: () => context.push('/restaurant/${restaurante.id}'),
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
                           leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              promotion.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.local_offer, size: 32),
                            ),
                          ),
                          title: Text(promotion.titulo,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          subtitle:  Text(
                            promotion.descripcion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                           onTap: () => context.push('/promotion/${promotion.id}'),
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
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              event.imageUrl,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.event, size: 32),
                            ),
                          ),
                          title: Text(event.titulo,
                              style: Theme.of(context).textTheme.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                           subtitle: Text(
                            DateFormat('d MMM, y', 'es_ES').format(event.fecha),
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ), 
                          onTap: () => context.push('/event/${event.id}'),
                        ),
                        emptyMessage:
                            'No hay eventos programados en este momento.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
        Text('Hotel', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
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
    required ProviderListenable<AsyncValue<List<T>>> provider,
    required Widget Function(T item) itemBuilder,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Consumer(builder: (context, ref, child) {
          final asyncValue = ref.watch(provider);
          return asyncValue.when(
            data: (items) {
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium)),
                );
              }
              return Card(
                 clipBehavior: Clip.antiAlias,
                 margin: EdgeInsets.zero,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) => itemBuilder(items[index]),
                  separatorBuilder: (context, index) => const Divider(height: 1),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        }),
      ],
    );
  }

  Future<void> _openMaps(BuildContext context, Casino casino) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (!context.mounted) return;

      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No hay aplicaciones de mapas instaladas.')),
        );
        return;
      }

      await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var map in availableMaps)
                    ListTile(
                      onTap: () async {
                        Navigator.pop(context);
                        await map.showDirections(
                          destination: Coords(casino.latitud, casino.longitud),
                          destinationTitle: casino.nombre,
                        );
                      },
                      title: Text(map.mapName),
                      leading: SvgPicture.asset(
                        map.icon,
                        height: 30.0,
                        width: 30.0,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir mapas: $e')),
        );
      }
    }
  }
}
