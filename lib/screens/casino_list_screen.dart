
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/screens/widgets/casino_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CasinoListScreen extends ConsumerWidget {
  const CasinoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casinosAsync = ref.watch(casinosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Casinos'),
      ),
      body: casinosAsync.when(
        data: (casinos) => ListView.builder(
          itemCount: casinos.length,
          itemBuilder: (context, index) {
            final Casino casino = casinos[index];
            return CasinoCard(
              casino: casino,
              onTap: () => context.go('/casinos/${casino.id}'),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
