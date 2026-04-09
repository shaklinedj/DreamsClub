import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casinoloyalty_flutter/models/game_config_model.dart';

class GameConfigFormScreen extends ConsumerStatefulWidget {
  final GameConfig? config;

  const GameConfigFormScreen({super.key, this.config});

  @override
  ConsumerState<GameConfigFormScreen> createState() =>
      _GameConfigFormScreenState();
}

class _GameConfigFormScreenState extends ConsumerState<GameConfigFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form state
  late bool _isActive;
  late bool _requiresLocation;
  late GameFrequency _frequency;
  late Set<int> _activeWeekdays;
  late Set<String> _allowedUserLevels;
  late TextEditingController _lockedMessageController;

  // Weekday labels in Spanish
  final _weekdayLabels = {
    1: 'Lun',
    2: 'Mar',
    3: 'Mié',
    4: 'Jue',
    5: 'Vie',
    6: 'Sáb',
    7: 'Dom',
  };

  // User levels
  final _userLevels = ['black', 'gold', 'platinum', 'blue'];

  @override
  void initState() {
    super.initState();
    final config = widget.config;
    _isActive = config?.isActive ?? true;
    _requiresLocation = config?.requiresLocation ?? true;
    _frequency = config?.frequency ?? GameFrequency.daily;
    _activeWeekdays = Set<int>.from(config?.activeWeekdays ?? []);
    _allowedUserLevels = Set<String>.from(config?.allowedUserLevels ?? []);
    _lockedMessageController =
        TextEditingController(text: config?.lockedMessage ?? '');
  }

  @override
  void dispose() {
    _lockedMessageController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (widget.config == null) return; // Can't create new, only edit

    setState(() => _isLoading = true);

    try {
      final updatedConfig = GameConfig(
        gameId: widget.config!.gameId,
        title: widget.config!.title,
        isActive: _isActive,
        requiresLocation: _requiresLocation,
        frequency: _frequency,
        activeWeekdays: _activeWeekdays.toList()..sort(),
        allowedUserLevels: _allowedUserLevels.toList(),
        lockedMessage: _lockedMessageController.text.isEmpty
            ? null
            : _lockedMessageController.text,
      );

      await FirebaseFirestore.instance
          .collection('game_configs')
          .doc(updatedConfig.gameId)
          .update(updatedConfig.toMap());

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar si es administrador
    final user = ref.watch(userProvider);
    if (!user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso Denegado')),
        body: const Center(child: Text('No tienes permisos de administrador.')),
      );
    }

    if (widget.config == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
            child: Text('No se recibió configuración para editar.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar ${widget.config!.title}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Game Info (read-only)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.games),
                          title: Text(widget.config!.title),
                          subtitle: Text('ID: ${widget.config!.gameId}'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Active Switch
                      _buildSectionTitle('Estado General'),
                      SwitchListTile(
                        title: const Text('Juego Activo'),
                        subtitle: const Text(
                            'Si está desactivado, nadie puede jugar (mantenimiento)'),
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                      SwitchListTile(
                        title: const Text('Requiere Ubicación (GPS)'),
                        subtitle: const Text(
                            'El usuario debe estar en un casino para jugar'),
                        value: _requiresLocation,
                        onChanged: (value) =>
                            setState(() => _requiresLocation = value),
                      ),
                      const Divider(height: 32),

                      // Frequency
                      _buildSectionTitle('Frecuencia de Juego'),
                      DropdownButtonFormField<GameFrequency>(
                        initialValue: _frequency,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Frecuencia permitida',
                        ),
                        items: GameFrequency.values.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Text(_getFrequencyLabel(f)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _frequency = value);
                        },
                      ),
                      const SizedBox(height: 24),

                      // Active Weekdays
                      _buildSectionTitle('Días Activos'),
                      const Text(
                        'Deja vacío para que esté disponible todos los días.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _weekdayLabels.entries.map((entry) {
                          final isSelected =
                              _activeWeekdays.contains(entry.key);
                          return FilterChip(
                            label: Text(entry.value),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _activeWeekdays.add(entry.key);
                                } else {
                                  _activeWeekdays.remove(entry.key);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Allowed User Levels
                      _buildSectionTitle('Niveles de Membresía Permitidos'),
                      const Text(
                        'Deja vacío para permitir a todos los niveles.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _userLevels.map((level) {
                          final isSelected = _allowedUserLevels.contains(level);
                          return FilterChip(
                            label: Text(_formatLevelName(level)),
                            selected: isSelected,
                            selectedColor: _getLevelColor(level),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _allowedUserLevels.add(level);
                                } else {
                                  _allowedUserLevels.remove(level);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Locked Message
                      _buildSectionTitle('Mensaje Personalizado'),
                      TextFormField(
                        controller: _lockedMessageController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Mensaje cuando está bloqueado (opcional)',
                          hintText: 'Ej: Disponible solo los fines de semana',
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      ElevatedButton.icon(
                        onPressed: _saveConfig,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Configuración'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getFrequencyLabel(GameFrequency frequency) {
    switch (frequency) {
      case GameFrequency.daily:
        return 'Una vez al día';
      case GameFrequency.weekly:
        return 'Una vez a la semana';
      case GameFrequency.unlimited:
        return 'Ilimitado';
      case GameFrequency.oncePerStay:
        return 'Una vez por visita al casino';
    }
  }

  String _formatLevelName(String level) {
    switch (level) {
      case 'black':
        return 'Black';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      case 'blue':
        return 'Blue';
      default:
        return level;
    }
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'black':
        return Colors.grey.shade800;
      case 'gold':
        return Colors.amber.shade300;
      case 'platinum':
        return Colors.grey.shade400;
      case 'blue':
        return Colors.blue.shade300;
      default:
        return Colors.grey;
    }
  }
}
