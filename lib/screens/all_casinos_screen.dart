import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/screens/widgets/casino_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllCasinosScreen extends ConsumerWidget {
  const AllCasinosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCasinos = ref.watch(casinosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conoce Nuestros Casinos'),
      ),
      body: allCasinos.when(
        data: (casinos) => ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: casinos.length,
          itemBuilder: (context, index) {
            final casino = casinos[index];
            return CasinoCard(casino: casino);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
