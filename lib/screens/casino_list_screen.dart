
import 'package:casinoloyalty_flutter/services/casino_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/casino_model.dart';

class CasinoListScreen extends StatefulWidget {
  const CasinoListScreen({super.key});

  @override
  State<CasinoListScreen> createState() => _CasinoListScreenState();
}

class _CasinoListScreenState extends State<CasinoListScreen> {
  final CasinoService _casinoService = CasinoService();
  late Future<List<Casino>> _casinosFuture;

  @override
  void initState() {
    super.initState();
    _casinosFuture = _casinoService.getAllCasinos();
  }

  Future<void> _setFavoriteAndNavigate(BuildContext context, Casino casino) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('favoriteCasino', casino.id);
    await prefs.setDouble('favoriteCasinoLat', casino.latitud);
    await prefs.setDouble('favoriteCasinoLng', casino.longitud);

    if (context.mounted) {
      context.go('/casinos/${casino.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un casino'),
      ),
      body: FutureBuilder<List<Casino>>(
        future: _casinosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron casinos.'));
          } else {
            final casinos = snapshot.data!;
            return ListView.builder(
              itemCount: casinos.length,
              itemBuilder: (context, index) {
                final casino = casinos[index];
                return ListTile(
                  leading: Image.asset(casino.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                  title: Text(casino.nombre),
                  subtitle: Text(casino.ciudad),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _setFavoriteAndNavigate(context, casino),
                );
              },
            );
          }
        },
      ),
    );
  }
}
