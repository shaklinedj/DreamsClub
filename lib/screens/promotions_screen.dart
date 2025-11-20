import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/offer_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:casinoloyalty_flutter/widgets/favorite_casino_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCasinoAsync = ref.watch(selectedCasinoProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Beneficios'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Saldo: ${user.points}',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontFamily: 'Monospace', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
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

          final offersAsync = ref.watch(offersProvider(casino.id));
          
          return offersAsync.when(
            data: (offers) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (offers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No hay beneficios disponibles actualmente.'),
                      ),
                    )
                  else
                    ...offers.map((offer) => _buildOfferCard(context, offer)),

                  const SizedBox(height: 20),
                  
                  // Birthday Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Theme.of(context).primaryColor, const Color(0xFFFFD700)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('¿Cumpleaños cerca?', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text(
                          'Recibe una cena gratis y \$20.000 en créditos jugables en tu mes de cumpleaños.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Theme.of(context).primaryColor,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Ver condiciones', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // Bottom padding for navbar
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error al cargar beneficios: $err')),
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(BuildContext context, dynamic offer) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(offer.icon, color: primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(offer.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: offer.pointsCost > 0 ? primaryColor.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        offer.pointsCost > 0 ? '${offer.pointsCost} pts' : 'GRATIS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: offer.pointsCost > 0 ? primaryColor : Colors.greenAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(offer.type, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(offer.validity, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
