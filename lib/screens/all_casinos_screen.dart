import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/screens/widgets/casino_card.dart';

import 'package:casinoloyalty_flutter/screens/coyhaique/coyhaique_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/widgets/animated_bell.dart';
import 'package:casinoloyalty_flutter/widgets/notifications_modal.dart';

class AllCasinosScreen extends ConsumerWidget {
  const AllCasinosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCasinos = ref.watch(casinosProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            CoyhaiqueShell.openDrawer();
          },
        ),
        title: const Text('Nuestros Casinos'),
        actions: [
          IconButton(
            icon: const AnimatedBell(),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const NotificationsModal(),
              );
            },
          ),
        ],
      ),
      body: allCasinos.when(
        data: (casinos) => ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: casinos.length,
          itemBuilder: (context, index) {
            final casino = casinos[index];
            return CasinoCard(
              casino: casino,
              onTap: () => context.push('/all-casinos/${casino.id}'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
