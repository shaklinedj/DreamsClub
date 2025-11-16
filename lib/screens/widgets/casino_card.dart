import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CasinoCard extends StatelessWidget {
  final Casino casino;
  final VoidCallback? onTap;

  const CasinoCard({super.key, required this.casino, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap ?? () => context.push('/all-casinos/casinos/${casino.id}'),
        child: Stack(
          alignment: Alignment.bottomLeft,
          children: [
            Ink.image(
              image: AssetImage(casino
                  .imageUrl), // CORREGIDO: AssetImage en lugar de NetworkImage
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              child: Container(), // Child necesario para Ink.image
            ),
            // Gradiente oscuro para asegurar la legibilidad del texto
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(204),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                casino.nombre, // Corregido para usar 'nombre'
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [const Shadow(blurRadius: 5, color: Colors.black87)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
