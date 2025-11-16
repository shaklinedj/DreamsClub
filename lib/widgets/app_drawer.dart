
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          InkWell(
            onTap: () {
              // Cierra el drawer y navega a la pantalla de perfil
              Navigator.pop(context);
              context.go('/profile');
            },
            child: UserAccountsDrawerHeader(
              accountName: Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(user.email),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage(user.profileImageUrl),
              ),
              decoration: BoxDecoration(
                color: user.levelColor, // Color basado en el nivel del usuario
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              context.go('/casinos');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
