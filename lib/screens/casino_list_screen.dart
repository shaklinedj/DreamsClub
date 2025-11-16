
import 'package:casinoloyalty_flutter/providers/casino_providers.dart' show casinosProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CasinoListScreen extends ConsumerWidget {
  const CasinoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casinos = ref.watch(casinosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuestros Casinos'),
      ),
      body: casinos.when(
        data: (data) => ListView.builder(
          itemCount: data.length,
          itemBuilder: (context, index) {
            final casino = data[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.go('/casino/${casino.id}'),
                child: Column(
                  children: [
                    SizedBox(
                      height: 200.0,
                      width: double.infinity,
                      child: Image.asset(
                        casino.imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    ListTile(
                      title: Text(casino.nombre),
                      subtitle: Text(casino.ciudad),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(error.toString())),
      ),
    );
  }
}
