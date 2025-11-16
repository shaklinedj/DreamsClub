
import 'package:casinoloyalty_flutter/services/user_prefs.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class DecisionScreen extends StatefulWidget {
  const DecisionScreen({super.key});

  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
    @override
  void initState() {
    super.initState();
    _checkFavoriteCasino();
  }

  Future<void> _checkFavoriteCasino() async {
    // Pequeño retraso para dar tiempo a la UI a renderizar el logo inicial
    await Future.delayed(const Duration(seconds: 2)); 

    final favoriteCasinoId = await UserPreferences.getFavoriteCasino();

    if (!mounted) return; 

    if (favoriteCasinoId != null) {
      // Si hay un casino favorito, navega a su detalle
      context.go('/casino/$favoriteCasinoId');
    } else {
      // Si no, navega a la pantalla de bienvenida/selección
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Esta pantalla solo muestra un logo centrado mientras decide a dónde ir
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
