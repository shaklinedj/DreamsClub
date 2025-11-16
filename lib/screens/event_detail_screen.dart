
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/event_model.dart';
import 'package:casinoloyalty_flutter/services/event_service.dart';
import 'package:intl/intl.dart';


// Provider para el servicio de eventos
final eventServiceProvider = Provider((ref) => EventService());

// Provider para obtener un evento específico por su ID
final eventDetailProvider = FutureProvider.family<Event, int>((ref, id) {
  return ref.watch(eventServiceProvider).getEventById(id);
});

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int id = int.parse(eventId);
    final eventAsyncValue = ref.watch(eventDetailProvider(id));

    return Scaffold(
      body: eventAsyncValue.when(
        data: (event) => CustomScrollView(
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
                  event.titulo,
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
                  event.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey,
                      child: const Center(
                        child: Icon(Icons.event, color: Colors.white, size: 80),
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
                      'Sobre el Evento',
                       style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, 
                        color: Theme.of(context).colorScheme.primary
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat("EEEE, d 'de' MMMM, y", 'es_ES').format(event.fecha),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      event.descripcion,
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
