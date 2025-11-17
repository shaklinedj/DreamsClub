import 'dart:io';

import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animated_icons/useanimations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
              child: UserAccountsDrawerHeader(
                accountName: Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: user.levelTextColor,
                  ),
                ),
                accountEmail: Text(
                  user.email,
                  style: TextStyle(
                    color: user.levelTextColor,
                  ),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundImage: _buildProfileImage(user.profileImageUrl),
                ),
                decoration: BoxDecoration(
                  color: user.levelColor,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Mi casino'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_giftcard),
              title: const Text('Promociones'),
              onTap: () {
                Navigator.pop(context);
                context.go('/promotions');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Eventos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/events');
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Restaurantes'),
              onTap: () {
                Navigator.pop(context);
                context.go('/restaurants');
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore),
              title: const Text('Explorar casinos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/all-casinos');
              },
            ),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _ThemeModeSection(
              themeMode: themeMode,
              onChanged: (mode) async {
                await themeNotifier.update(mode);
              },
            ),
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
      ),
    );
  }
}

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection({
    required this.themeMode,
    required this.onChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 64,
                  width: 64,
                  child: Lottie.asset(
                    Useanimations.settings,
                    repeat: true,
                    frameRate: FrameRate.max,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de tema',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Elige modo claro, oscuro o sincroniza con tu sistema.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeMode,
              dense: true,
              secondary: const Icon(Icons.auto_mode),
              title: const Text('Tema del sistema'),
              subtitle:
                  const Text('Sigue automáticamente el modo del dispositivo.'),
              onChanged: (mode) {
                if (mode != null) onChanged(mode);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeMode,
              dense: true,
              secondary: const Icon(Icons.light_mode),
              title: const Text('Modo claro'),
              onChanged: (mode) {
                if (mode != null) onChanged(mode);
              },
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeMode,
              dense: true,
              secondary: const Icon(Icons.dark_mode),
              title: const Text('Modo oscuro'),
              onChanged: (mode) {
                if (mode != null) onChanged(mode);
              },
            ),
          ],
        ),
      ),
    );
  }
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
