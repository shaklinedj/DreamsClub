import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/theme_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController.text = user.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Perfil'),
          ListTile(
            title: const Text('Nombre'),
            subtitle: _isEditingName
                ? TextField(
                    controller: _nameController,
                    autofocus: true,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        ref.read(userProvider.notifier).updateName(value);
                        setState(() {
                          _isEditingName = false;
                        });
                      }
                    },
                  )
                : Text(user.name),
            trailing: IconButton(
              icon: Icon(_isEditingName ? Icons.check : Icons.edit),
              onPressed: () {
                if (_isEditingName) {
                  if (_nameController.text.isNotEmpty) {
                    ref
                        .read(userProvider.notifier)
                        .updateName(_nameController.text);
                    setState(() {
                      _isEditingName = false;
                    });
                  }
                } else {
                  setState(() {
                    _isEditingName = true;
                  });
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Correo Electrónico'),
            subtitle: Text(user.email),
            trailing: const Icon(Icons.lock_outline, size: 16),
          ),
          ListTile(
            title: const Text('Fecha de Nacimiento'),
            subtitle: Text(user.birthday != null
                ? DateFormat('dd/MM/yyyy').format(user.birthday!)
                : 'No configurada'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: user.birthday ?? DateTime(1990),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                ref.read(userProvider.notifier).updateBirthday(date);
              }
            },
          ),
          const Divider(),
          _buildSectionHeader('Preferencias'),
          ListTile(
            title: const Text('Casino Favorito'),
            subtitle: Text(user.favoriteCasinoId != null
                ? 'Casino #${user.favoriteCasinoId}'
                : 'No seleccionado'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showFavoriteCasinoDialog(context, user);
            },
          ),
          SwitchListTile(
            title: const Text('Notificaciones'),
            value: true, // Placeholder
            onChanged: (value) {
              // Implement notification toggle
            },
          ),
          const Divider(),
          _buildSectionHeader('Apariencia'),
          ListTile(
            title: const Text('Tema'),
            subtitle: Text(_getThemeModeName(themeMode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showThemeDialog(context, themeMode, themeNotifier);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
    }
  }

  void _showThemeDialog(
      BuildContext context, ThemeMode currentMode, dynamic notifier) {
    showDialog(
      context: context,
      builder: (context) {
        ThemeMode selectedMode = currentMode;
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = selectedMode == ThemeMode.dark;
            final isSystem = selectedMode == ThemeMode.system;

            return AlertDialog(
              title: const Text('Seleccionar Tema'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Usar tema del sistema'),
                    subtitle:
                        const Text('Sigue la configuración del dispositivo'),
                    value: isSystem,
                    onChanged: (value) {
                      setState(() {
                        selectedMode =
                            value ? ThemeMode.system : ThemeMode.light;
                      });
                    },
                  ),
                  if (!isSystem) ...[
                    const Divider(),
                    SwitchListTile(
                      title: Text(isDark ? 'Tema Oscuro' : 'Tema Claro'),
                      subtitle: Text(isDark
                          ? 'Modo nocturno activado'
                          : 'Modo día activado'),
                      value: isDark,
                      onChanged: (value) {
                        setState(() {
                          selectedMode =
                              value ? ThemeMode.dark : ThemeMode.light;
                        });
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    notifier.update(selectedMode);
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFavoriteCasinoDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) {
        final casinosAsync = ref.watch(casinosProvider);
        return AlertDialog(
          title: const Text('Seleccionar Casino Favorito'),
          content: SizedBox(
            width: double.maxFinite,
            child: casinosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
              data: (casinos) {
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: casinos.length,
                  itemBuilder: (context, index) {
                    final casino = casinos[index];
                    final isSelected = user.favoriteCasinoId == casino.id;
                    return ListTile(
                      title: Text(casino.nombre),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                            )
                          : const Icon(
                              Icons.circle_outlined,
                              color: Colors.grey,
                            ),
                      onTap: () {
                        ref
                            .read(userProvider.notifier)
                            .updateFavoriteCasino(casino.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
