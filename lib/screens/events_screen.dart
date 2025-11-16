import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCasinoId = ref.watch(activeCasinoIdProvider);

    if (activeCasinoId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Eventos')),
        body: const Center(
          child: Text('Selecciona un casino para ver sus eventos.'),
        ),
      );
    }

    final events = ref.watch(eventsProvider(activeCasinoId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos del Casino'),
      ),
      body: events.when(
        data: (List<Event> eventList) {
          if (eventList.isEmpty) {
            return const Center(
              child: Text('No hay eventos disponibles para este casino.'),
            );
          }
          return ListView.builder(
            itemCount: eventList.length,
            itemBuilder: (context, index) {
              final event = eventList[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(event.titulo),
                  subtitle: Text(event.descripcion),
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
