import 'package:flutter/material.dart';

class FavoriteCasinoPlaceholder extends StatelessWidget {
  const FavoriteCasinoPlaceholder({
    super.key,
    required this.onSelect,
    this.icon = Icons.casino,
    this.message =
        'Selecciona tu casino favorito o permite la ubicación para mostrarte contenido relevante.',
  });

  final VoidCallback onSelect;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.explore),
              label: const Text('Elegir casino'),
            ),
          ],
        ),
      ),
    );
  }
}
