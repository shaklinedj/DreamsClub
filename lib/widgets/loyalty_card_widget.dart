
import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoyaltyCardWidget extends StatelessWidget {
  final User user;

  const LoyaltyCardWidget({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final pointsFormatter = NumberFormat.decimalPattern('en_US');

    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.grey[900]!, Colors.grey[850]!, Colors.black],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'CASINO LOYALTY',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Chip(
                  label: Text(user.levelName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white.withAlpha(230), // 90% opacity (255 * 0.9 = 229.5)
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Icon(Icons.sim_card, size: 40, color: Colors.white38),
            const SizedBox(height: 20),
            Text(
              '**** **** **** 1234', // Número de tarjeta de ejemplo
              style: TextStyle(
                color: Colors.white.withAlpha(204), // 80% opacity (255 * 0.8 = 204)
                fontSize: 22,
                letterSpacing: 2.0,
                fontFamily: 'monospace', // Da un look de tarjeta de crédito
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'PUNTOS',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      pointsFormatter.format(user.points),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    const Text(
                      'SALDO',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      currencyFormatter.format(user.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              user.name.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
