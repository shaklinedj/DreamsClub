import 'dart:io';

import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final primaryColor = user.levelColor;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: true,
        child: ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
              child: UserAccountsDrawerHeader(
                accountName: Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                accountEmail: Text(
                  user.email,
                  style: const TextStyle(
                    color: Colors.white70,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  radius: 36,
                  backgroundColor: primaryColor,
                  child: CircleAvatar(
                    radius: 34,
                    backgroundImage: _buildProfileImage(user.profileImageUrl),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                      bottom: BorderSide(
                          color: primaryColor.withValues(alpha: 0.5))),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: primaryColor),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.card_membership, color: primaryColor),
              title: const Text('Beneficios Club'),
              onTap: () {
                Navigator.pop(context);
                context.push('/benefits');
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: primaryColor),
              title: const Text('Mi casino'),
              onTap: () {
                Navigator.pop(context);
                if (user.favoriteCasinoId != null) {
                  context.push('/all-casinos/${user.favoriteCasinoId}');
                } else {
                  context.push('/all-casinos');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.explore, color: primaryColor),
              title: const Text('Explorar casinos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/all-casinos');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.grey),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _buildProfileImage(String path) {
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    final file = File(path);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return const AssetImage('assets/images/perfil_imagen.png');
  }
}
