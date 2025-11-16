
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavigation extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Casino Loyalty'),
        actions: [
          IconButton(
            icon: const Icon(Icons.casino_outlined),
            tooltip: 'Cambiar de casino',
            onPressed: () => context.go('/casinos'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: child,
    );
  }
}
