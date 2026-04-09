import 'package:flutter/material.dart';

class FavoriteCasinoPlaceholder extends StatelessWidget {
  final IconData? icon;
  final String? message;
  final VoidCallback onSelect;

  const FavoriteCasinoPlaceholder({
    super.key,
    this.icon,
    this.message,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.casino,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 24),
            Text(
              message ?? 'Selecciona tu casino favorito para comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.star),
              label: const Text('Seleccionar Casino'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
