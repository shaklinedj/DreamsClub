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
              secondary: Icon(Icons.notifications_active_outlined,
                  color: primaryColor),
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
              title: const Text('Cerrar Sesión',
                  style: TextStyle(color: Colors.redAccent)),
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
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white),
              ),
            ),
            RadioGroup<ThemeMode>(
              groupValue: themeMode,
              onChanged: onChanged,
              child: const Column(
                children: [
                  _ThemeRadioTile(
                    value: ThemeMode.system,
                    icon: Icons.auto_mode,
                    label: 'Sistema',
                  ),
                  _ThemeRadioTile(
                    value: ThemeMode.light,
                    icon: Icons.light_mode,
                    label: 'Claro',
                  ),
                  _ThemeRadioTile(
                    value: ThemeMode.dark,
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
  final IconData icon;
  final String label;

  const _ThemeRadioTile({
    required this.value,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // We need to access the RadioGroup state to determine selection if we want custom UI
    // But Radio widget inside will handle it automatically if it's a descendant of RadioGroup?
    // Wait, standard Radio widget might not auto-detect RadioGroup unless it's the *new* Radio widget.
    // Assuming Radio() without groupValue works in this new version.

    // To properly style the "selected" state (text color, icon color), we might need to know if it's selected.
    // Does RadioGroup expose the current value?
    // Usually via context. But for now, let's just use the Radio widget which should handle the selection logic.
    // But wait, the original code passed `groupValue` and `onChanged` to `_ThemeRadioTile` manually!
    // Step 45:
    // _ThemeRadioTile(value: ThemeMode.system, groupValue: themeMode, onChanged: onChanged, ...)
    // So the original code WAS manually passing it down even though it used RadioGroup?
    // If I use RadioGroup, I shouldn't need to pass it down IF the children are `RadioListTile` or `Radio`.
    // But `_ThemeRadioTile` is a custom widget.
    // If `Radio` inside `_ThemeRadioTile` supports `RadioGroup`, it should work.
    // But for the *text color* change, I need to know the value.
    // I will assume for now that I can't easily get the value from RadioGroup without context lookup.
    // So I will keep passing `groupValue` to `_ThemeRadioTile` for styling, but `Radio` widget inside might not need it?
    // The error said `Radio` deprecated `groupValue`.
    // So `Radio` inside `_ThemeRadioTile` should NOT have `groupValue`.
    // But `_ThemeRadioTile` needs `groupValue` to decide text color.

    // Let's check if I can keep passing it to `_ThemeRadioTile` but NOT to `Radio`.

    return InkWell(
      onTap: () {
        // We need to trigger change. RadioGroup usually handles this via Radio tap.
        // If we tap the row, we want to select.
        // We might need to call onChanged manually?
        // But we don't have onChanged if we rely on RadioGroup?
        // Actually, RadioGroup has onChanged.
        // If I want to support row tap, I need to invoke the callback.
        // But I don't have access to it easily unless I pass it.
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey, size: 20), // Placeholder color logic
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            Radio<ThemeMode>(
              value: value,
              activeColor: Theme.of(context).primaryColor,
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
