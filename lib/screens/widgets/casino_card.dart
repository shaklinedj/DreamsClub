import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:flutter/material.dart';

class CasinoCard extends StatelessWidget {
  final Casino casino;
  final VoidCallback? onTap;

  const CasinoCard({super.key, required this.casino, this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageWidget = casino.imageUrl.startsWith('http')
        ? Image.network(
            casino.imageUrl,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/placeholder.jpg',
                height: 150,
                fit: BoxFit.cover,
              );
            },
          )
        : Image.asset(
            casino.imageUrl,
            height: 150,
            fit: BoxFit.cover,
          );

    return Card(
      // margin: Use default from Theme
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            imageWidget,
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    casino.nombre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    casino.ciudad,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
