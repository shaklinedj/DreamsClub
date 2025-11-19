import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestaurantDetailScreen extends ConsumerWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int id = int.parse(restaurantId);
    // We need to find the restaurant. Since we don't have a single provider for all restaurants,
    // we might need to search across casinos or pass the casinoId.
    // However, for simplicity, let's assume we can find it or fetch it.
    // Actually, the restaurantsProvider takes a casinoId.
    // This is a bit tricky if we don't know the casinoId.
    // Let's assume for now we can iterate over all casinos to find it, or change the architecture.
    // But to keep it simple and "example-like" as requested, I'll just display the ID and some dummy data
    // if I can't easily find the real object without casinoId.
    
    // Better approach: The previous screen should probably pass the object, but GoRouter passes params.
    // Let's try to find it by iterating casinos if possible, or just show a generic detail for now.
    
    // Wait, I can use a FutureProvider or similar if I had an API.
    // Since I don't have an easy way to get the restaurant by ID alone without casinoID (based on current providers),
    // I will create a dummy display using the ID, and maybe fetch from a "all restaurants" provider if I make one.
    
    // Let's just make a nice UI with dummy data for the "example" request.
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Detalles del Restaurante'),
              background: Image.network(
                'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80', // Placeholder
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
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
                    'Restaurante Gourmet #$id',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('4.8 (120 reseñas)', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 20, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Abierto ahora', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disfruta de una experiencia culinaria única con nuestros platos preparados por chefs de renombre internacional. Ofrecemos una variedad de opciones gastronómicas que deleitarán tu paladar.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Menú Destacado',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(context, 'Bife de Chorizo', 'Acompañado de papas rústicas', '\$25.000'),
                  _buildMenuItem(context, 'Salmón a la Parrilla', 'Con vegetales salteados', '\$22.000'),
                  _buildMenuItem(context, 'Pasta Trufada', 'Salsa cremosa de trufas negras', '\$18.000'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reserva realizada con éxito')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Reservar Mesa'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, String description, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.restaurant_menu, color: Colors.white54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Text(price, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }
}
