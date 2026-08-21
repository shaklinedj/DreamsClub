import 'dart:convert';
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
    final primaryColor = Theme.of(context).primaryColor;

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
                context.push('/settings');
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
              leading: const Text('🎁', style: TextStyle(fontSize: 22)),
              title: const Text(
                'Mis Premios & Vouchers',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
              ),
              subtitle: const Text(
                'Códigos de canje e historial',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Color(0xFFD4AF37)),
              onTap: () {
                Navigator.pop(context);
                context.push('/my-prizes');
              },
            ),
            ListTile(
              leading: Icon(Icons.emoji_events_outlined, color: primaryColor),
              title: const Text('Mis Logros & Rachas'),
              onTap: () {
                Navigator.pop(context);
                context.go('/achievements');
              },
            ),
            ListTile(
              leading: Icon(Icons.stars_rounded, color: primaryColor),
              title: const Text('Beneficios Club'),
              onTap: () {
                Navigator.pop(context);
                context.push('/benefits');
              },
            ),
            ListTile(
              leading: Icon(Icons.casino_outlined, color: primaryColor),
              title: const Text('Nuestros Casinos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/casinos');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined, color: primaryColor),
              title: const Text('Configuración'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.payments_outlined, color: primaryColor),
              title: const Text('DreamsPay'),
              subtitle: const Text(
                'Paga rápido y seguro',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                final uri = Uri(
                  path: '/webview',
                  queryParameters: {
                    'url': 'https://coyhaique.dreams.cl/dreamspay/',
                    'title': 'DreamsPay',
                  },
                );
                context.push(uri.toString());
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
    if (path.isEmpty) {
      return const AssetImage('assets/images/logo-dreams.png');
    }
    if (path.startsWith('data:image')) {
      try {
        final commaIndex = path.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = path.substring(commaIndex + 1);
          return MemoryImage(base64Decode(base64Data));
        }
      } catch (_) {}
    }
    if (path.startsWith('assets/')) {
      return AssetImage(path);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
    return const AssetImage('assets/images/logo-dreams.png');
  }
}
