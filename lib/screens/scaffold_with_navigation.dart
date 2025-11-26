import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavigation extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Tomamos control manual del botón "Atrás"
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        // Check if drawer is open
        if (Scaffold.of(context).hasDrawer &&
            Scaffold.of(context).isDrawerOpen) {
          Navigator.of(context).pop(); // Close drawer
          return;
        }

        final router = GoRouter.of(context);
        // Si hay una pantalla anterior en el stack, simplemente vuelve.
        if (router.canPop()) {
          router.pop();
        } else {
          // Si no, muestra un diálogo de confirmación para salir.
          final bool? shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¿Salir de la aplicación?'),
              content: const Text(
                  '¿Estás seguro de que deseas cerrar la aplicación?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sí'),
                ),
              ],
            ),
          );
          if (shouldPop ?? false) {
            // En un escenario real, podríamos llamar a SystemNavigator.pop()
            // para cerrar la aplicación, pero lo evitamos aquí para no afectar el IDE.
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Casino Loyalty'),
          actions: [
            IconButton(
              icon: const Icon(Icons.casino_outlined),
              tooltip: 'Cambiar de casino',
              onPressed: () => context.go('/select-favorite'),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: child,
      ),
    );
  }
}
