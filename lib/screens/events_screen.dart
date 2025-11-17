import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/event_providers.dart';
import 'package:casinoloyalty_flutter/widgets/favorite_casino_placeholder.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCasinoAsync = ref.watch(selectedCasinoProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Eventos del Casino'),
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

          final events = ref.watch(eventsProvider(casino.id));
          return events.when(
            data: (List<Event> eventList) {
              if (eventList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text('No hay eventos programados en ${casino.nombre}.'),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(eventsProvider(casino.id).future),
                child: ListView.builder(
                  itemCount: eventList.length,
                  itemBuilder: (context, index) {
                    final event = eventList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => context.push('/event/${event.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                event.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.event, size: 64),
                              ),
                            ),
                            ListTile(
                              title: Text(event.titulo),
                              subtitle: Text(event.descripcion),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
      ),
    );
  }
}
