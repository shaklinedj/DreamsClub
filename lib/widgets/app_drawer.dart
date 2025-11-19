import 'dart:io';

import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/background_distance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _distanceNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final enabled = await BackgroundDistanceService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _distanceNotificationsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleDistanceNotifications(bool value) async {
    if (value) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        _showSnackBar('Se requieren permisos de notificación');
        return;
      }
    }

    setState(() => _distanceNotificationsEnabled = value);
    try {
      if (value) {
        await BackgroundDistanceService.enableNotifications();
        _showSnackBar('Notificaciones de distancia activadas');
      } else {
        await BackgroundDistanceService.disableNotifications();
        _showSnackBar('Notificaciones de distancia desactivadas');
      }
    } catch (e) {
      setState(() => _distanceNotificationsEnabled = !value);
      _showSnackBar('Error al cambiar la configuración');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final primaryColor = Theme.of(context).primaryColor;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  color: const Color(0xFF1A1A1A), // kSurfaceColor
                  border: Border(bottom: BorderSide(color: primaryColor.withValues(alpha: 0.5))),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: primaryColor),
              title: const Text('Mi Perfil'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: primaryColor),
              title: const Text('Mi casino'),
              onTap: () {
                Navigator.pop(context);
                context.go('/home');
              },
            ),
            ListTile(
              leading: Icon(Icons.card_giftcard, color: primaryColor),
              title: const Text('Promociones'),
              onTap: () {
                Navigator.pop(context);
                context.go('/promotions');
              },
            ),
            ListTile(
              leading: Icon(Icons.event, color: primaryColor),
              title: const Text('Eventos'),
              onTap: () {
                Navigator.pop(context);
                context.go('/events');
              },
            ),
            ListTile(
              leading: Icon(Icons.restaurant_menu, color: primaryColor),
              title: const Text('Restaurantes'),
              onTap: () {
                Navigator.pop(context);
                context.go('/restaurants');
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
            const Divider(color: Colors.white10),
            SwitchListTile(
              secondary: Icon(Icons.notifications_active_outlined, color: primaryColor),
              title: const Text('Notificaciones de distancia'),
              subtitle: Text(
                'Avisar a más de ${BackgroundDistanceService.distanceThresholdKm.toInt()}km',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: _distanceNotificationsEnabled,
              onChanged: _toggleDistanceNotifications,
              activeTrackColor: primaryColor,
              activeThumbColor: Colors.white,
            ),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _ThemeModeSection(
              themeMode: themeMode,
              onChanged: (mode) async {
                if (mode != null) await themeNotifier.update(mode);
              },
            ),
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
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
  final ValueChanged<ThemeMode?> onChanged;

  @override
  Widget build(BuildContext context) {
    // final primaryColor = Theme.of(context).primaryColor; // Unused
    return Card(
      color: const Color(0xFF2A2A2A), // kSurfaceLightColor
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Text(
                'Tema',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            // Usamos Radio<ThemeMode> dentro de ListTile para simular RadioListTile
            // pero compatible con la nueva recomendación de no usar groupValue en RadioListTile directamente
            // o simplemente ignoramos la deprecación por ahora ya que RadioGroup es muy nuevo.
            // Sin embargo, para limpiar el código, podemos usar una implementación manual limpia:
            
            RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: onChanged,
              child: Column(
                children: [
                  _ThemeRadioTile(
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: onChanged,
                    icon: Icons.auto_mode,
                    label: 'Sistema',
                  ),
                  _ThemeRadioTile(
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: onChanged,
                    icon: Icons.light_mode,
                    label: 'Claro',
                  ),
                  _ThemeRadioTile(
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: onChanged,
                    icon: Icons.dark_mode,
                    label: 'Oscuro',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeRadioTile extends StatelessWidget {
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;
  final IconData icon;
  final String label;

  const _ThemeRadioTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isSelected = value == groupValue;
    
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            Radio<ThemeMode>(
              value: value,
              activeColor: primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
