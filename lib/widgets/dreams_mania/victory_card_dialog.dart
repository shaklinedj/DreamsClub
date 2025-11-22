import 'package:flutter/material.dart';

class VictoryCardDialog extends StatelessWidget {
  final int score;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const VictoryCardDialog({
    super.key,
    required this.score,
    required this.onShare,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4AF37), width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¡DREAMS MANÍA!',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'HAS GANADO',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '\$$score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'CRÉDITOS',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share, color: Colors.black),
              label: const Text('COMPARTIR VICTORIA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onClose,
              child: const Text(
                'CERRAR',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
