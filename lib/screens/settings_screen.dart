// ignore_for_file: prefer_const_constructors
import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/background_distance_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'General',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            secondary:
                Icon(Icons.notifications_active_outlined, color: primaryColor),
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
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Apariencia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _ThemeModeSection(
            themeMode: themeMode,
            onChanged: (mode) async {
              if (mode != null) await themeNotifier.update(mode);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Desarrollador',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _UserLevelSection(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Preferencias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _UserPreferencesSection(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Información',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Versión de la aplicación'),
            subtitle: const Text('1.0.0+38'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de privacidad'),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
        ],
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
    return RadioGroup<ThemeMode>(
      groupValue: themeMode,
      onChanged: onChanged,
      child: const Column(
        children: [
          RadioListTile<ThemeMode>(
            title: Text('Sistema'),
            value: ThemeMode.system,
            secondary: Icon(Icons.auto_mode),
          ),
          RadioListTile<ThemeMode>(
            title: Text('Claro'),
            value: ThemeMode.light,
            secondary: Icon(Icons.light_mode),
          ),
          RadioListTile<ThemeMode>(
            title: Text('Oscuro'),
            value: ThemeMode.dark,
            secondary: Icon(Icons.dark_mode),
          ),
        ],
      ),
    );
  }
}

class _UserLevelSection extends ConsumerWidget {
  const _UserLevelSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nivel de Usuario',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<UserLevel>(
                  value: user.level,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (UserLevel? newValue) {
                    if (newValue != null) {
                      userNotifier.updateLevel(newValue);
                    }
                  },
                  items: UserLevel.values
                      .map<DropdownMenuItem<UserLevel>>((UserLevel value) {
                    return DropdownMenuItem<UserLevel>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(Icons.circle,
                              color: User(
                                      name: '',
                                      email: '',
                                      profileImageUrl: '',
                                      level: value,
                                      points: 0,
                                      balance: 0)
                                  .levelColor,
                              size: 16),
                          const SizedBox(width: 12),
                          Text(value.name.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserPreferencesSection extends ConsumerWidget {
  const _UserPreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.casino_outlined, color: primaryColor),
          title: const Text('Casino Favorito'),
          subtitle: Text(user.favoriteCasino ?? 'Seleccionar'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            final selected = await showDialog<String>(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Selecciona tu Casino'),
                children: [
                  'Monticello',
                  'Iquique',
                  'Temuco',
                  'Valdivia',
                  'Puerto Varas',
                  'Coyhaique',
                  'Punta Arenas'
                ].map((casino) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, casino),
                    child: Text(casino),
                  );
                }).toList(),
              ),
            );

            if (selected != null) {
              userNotifier.updateFavoriteCasino(selected);
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.cake_outlined, color: primaryColor),
          title: const Text('Fecha de Cumpleaños'),
          subtitle: Text(user.birthday != null
              ? '${user.birthday!.day}/${user.birthday!.month}/${user.birthday!.year}'
              : 'Configurar'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: user.birthday ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );

            if (date != null) {
              userNotifier.updateBirthday(date);
            }
          },
        ),
      ],
    );
  }
}
