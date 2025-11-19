import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:casinoloyalty_flutter/widgets/favorite_casino_placeholder.dart';
import 'package:casinoloyalty_flutter/widgets/loyalty_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final selectedCasinoAsync = ref.watch(selectedCasinoProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      // AppBar eliminado para parecerse más a gemeniapp que usa un diseño full screen con scroll
      // Pero mantenemos el drawer accesible si se desliza o añadimos un botón
      appBar: AppBar(
        title: const Text('Dreams Club'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100), // Padding bottom extra para el navbar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Resumen de Usuario (Puntos y Nivel)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Colors.black,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bienvenido de nuevo,', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${user.levelName} Member',
                          style: TextStyle(
                            color: Colors.grey[900],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('PUNTOS DREAMS ACUMULADOS', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${user.points}',
                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Text('pts', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progreso a siguiente nivel', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('60000 pts', style: TextStyle(color: Colors.grey, fontSize: 12)), // Mock target
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: user.points / 60000,
                      backgroundColor: Colors.grey[800],
                      color: Theme.of(context).primaryColor,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botones de Acción Rápida
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.qr_code,
                    label: 'Tarjeta Digital',
                    onTap: () {
                      // Mostrar modal QR (reutilizando lógica si es posible o duplicando por ahora)
                      // Idealmente llamar al método de ScaffoldWithNavBar o usar un provider global de UI
                      showDialog(
                        context: context,
                        barrierColor: Colors.black.withValues(alpha : 0.9),
                        builder: (context) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(20),
                          child: LoyaltyCardWidget(user: user),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.card_giftcard,
                    label: 'Mis Canjes',
                    onTap: () => context.go('/promotions'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sección Destacado (Casino Seleccionado)
            Row(
              children: [
                Icon(Icons.star, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 8),
                const Text('Tu Casino Favorito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            
            selectedCasinoAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (casino) {
                if (casino == null) {
                  return _EmptyState(onAction: () => context.go('/select-favorite'));
                }
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/all-casinos/${casino.id}'),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: AssetImage(casino.imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(casino.nombre, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(casino.ciudad, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
             Row(
              children: [
                Icon(Icons.local_offer, color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 8),
                const Text('Destacado para ti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.videogame_asset, color: Colors.indigoAccent),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sorteo "La Suerte de Dreams"', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('¡Participa por un auto 0KM hoy!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2A2A), // kSurfaceLightColor
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAction});

  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return FavoriteCasinoPlaceholder(onSelect: onAction);
  }
}
