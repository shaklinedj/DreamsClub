
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:flutter/material.dart';

class CasinoCard extends StatelessWidget {
  final Casino casino;
  final VoidCallback? onTap;

  const CasinoCard({super.key, required this.casino, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.network(
              casino.imageUrl,
              height: 150,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    casino.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(casino.ciudad),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
