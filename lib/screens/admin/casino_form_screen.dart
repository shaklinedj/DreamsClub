import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/data/repositories/admin_casino_repository.dart';
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:uuid/uuid.dart';

class CasinoFormScreen extends ConsumerStatefulWidget {
  final Casino? casino;

  const CasinoFormScreen({super.key, this.casino});

  @override
  ConsumerState<CasinoFormScreen> createState() => _CasinoFormScreenState();
}

class _CasinoFormScreenState extends ConsumerState<CasinoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = AdminCasinoRepository();
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nombreController;
  late TextEditingController _ciudadController;
  late TextEditingController _direccionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _latController;
  late TextEditingController _lngController;

  // Additional Fields
  final List<String> _features = [];
  final TextEditingController _featureController = TextEditingController();
  final Map<String, String> _schedules = {};
  final TextEditingController _scheduleDayController = TextEditingController();
  final TextEditingController _scheduleTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.casino?.nombre ?? '');
    _ciudadController =
        TextEditingController(text: widget.casino?.ciudad ?? '');
    _direccionController =
        TextEditingController(text: widget.casino?.direccion ?? '');
    _imageUrlController =
        TextEditingController(text: widget.casino?.imageUrl ?? '');
    _descriptionController =
        TextEditingController(text: widget.casino?.description ?? '');
    _latController =
        TextEditingController(text: widget.casino?.latitud.toString() ?? '');
    _lngController =
        TextEditingController(text: widget.casino?.longitud.toString() ?? '');

    if (widget.casino != null) {
      _features.addAll(widget.casino!.features);
      if (widget.casino!.schedules != null) {
        _schedules.addAll(widget.casino!.schedules!);
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ciudadController.dispose();
    _direccionController.dispose();
    _imageUrlController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _featureController.dispose();
    _scheduleDayController.dispose();
    _scheduleTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveCasino() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final lat = double.tryParse(_latController.text) ?? 0.0;
      final lng = double.tryParse(_lngController.text) ?? 0.0;

      final newCasino = Casino(
        id: widget.casino?.id ?? const Uuid().v4(),
        nombre: _nombreController.text,
        ciudad: _ciudadController.text,
        direccion: _direccionController.text,
        imageUrl: _imageUrlController.text,
        description: _descriptionController.text,
        latitud: lat,
        longitud: lng,
        features: _features,
        rating: widget.casino?.rating ?? 4.5,
        schedules: _schedules,
      );

      if (widget.casino == null) {
        await _repository.createCasino(newCasino);
      } else {
        await _repository.updateCasino(newCasino);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(widget.casino == null
                  ? 'Casino creado correctamente'
                  : 'Casino actualizado correctamente')),
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

    final isEditing = widget.casino != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Casino' : 'Nuevo Casino'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'El nombre es obligatorio'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ciudadController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'La ciudad es obligatoria'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _direccionController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'La dirección es obligatoria'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL de Imagen',
                        border: OutlineInputBorder(),
                        hintText: 'https://ejemplo.com/imagen.jpg',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    if (_imageUrlController.text.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _imageUrlController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[200],
                              child: const Center(
                                  child: Icon(Icons.broken_image, size: 50)),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Latitud',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Longitud',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Características'),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _featureController,
                            decoration: const InputDecoration(
                              hintText: 'Ej: Sala de Póker',
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addFeature(),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: _addFeature,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: _features.map((feature) {
                        return Chip(
                          label: Text(feature),
                          onDeleted: () {
                            setState(() {
                              _features.remove(feature);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Horarios'),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _scheduleDayController,
                            decoration: const InputDecoration(
                              hintText: 'Día(s)',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _scheduleTimeController,
                            decoration: const InputDecoration(
                              hintText: 'Horario (24h)',
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addSchedule(),
                          ),
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.add_circle, color: Colors.blue),
                          onPressed: _addSchedule,
                        ),
                      ],
                    ),
                    if (_schedules.isNotEmpty)
                      Card(
                        margin: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: _schedules.entries.map((entry) {
                            return ListTile(
                              title: Text(entry.key),
                              subtitle: Text(entry.value),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 20, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _schedules.remove(entry.key);
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveCasino,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEditing ? 'Actualizar' : 'Crear'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _addFeature() {
    final text = _featureController.text.trim();
    if (text.isNotEmpty && !_features.contains(text)) {
      setState(() {
        _features.add(text);
        _featureController.clear();
      });
    }
  }

  void _addSchedule() {
    final day = _scheduleDayController.text.trim();
    final time = _scheduleTimeController.text.trim();
    if (day.isNotEmpty && time.isNotEmpty) {
      setState(() {
        _schedules[day] = time;
        _scheduleDayController.clear();
        _scheduleTimeController.clear();
      });
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
