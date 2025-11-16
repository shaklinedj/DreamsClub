
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/casino_data.dart';
import '../models/casino.dart';

class CasinoListScreen extends StatelessWidget {
  const CasinoListScreen({super.key});

  Future<void> _setFavoriteAndNavigate(BuildContext context, Casino casino) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('favoriteCasino', casino.id);

    if (context.mounted) {
      context.go('/casino/${casino.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona un casino'),
      ),
      body: ListView.builder(
        itemCount: casinos.length,
        itemBuilder: (context, index) {
          final casino = casinos[index];
          return ListTile(
            leading: Image.network(casino.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
            title: Text(casino.name),
            subtitle: Text(casino.location),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _setFavoriteAndNavigate(context, casino),
          );
        },
      ),
    );
  }
}
