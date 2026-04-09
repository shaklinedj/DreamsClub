import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _ensureContinuousLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse) {
        // Intentar solicitar el permiso "always" directamente
        final elevated = await Geolocator.requestPermission();

        // Si aún no se obtuvo always, mostrar el diálogo para ir a ajustes
        if (elevated != LocationPermission.always) {
          if (!mounted) return;
          if (context.mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Permiso de ubicación continua'),
                content: const Text(
                  'Para registrar visitas en segundo plano y desbloquear logros automáticamente, necesitas habilitar "Permitir siempre" en los ajustes del sistema.\n\nEsto permitirá que la app detecte cuando visitas un casino, incluso cuando no la estés usando.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Ahora no'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await Geolocator.openAppSettings();
                    },
                    child: const Text('Abrir Ajustes'),
                  ),
                ],
              ),
            );
          }
        } else {
          // Éxito - mostrar confirmación
          if (!mounted) return;
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Permiso de ubicación continua activado'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (_) {
      // Silenciar errores (no bloquea UX)
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final File file = File(pickedFile.path);
      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference refStorage =
          FirebaseStorage.instance.ref().child('user_profiles').child(fileName);

      final UploadTask uploadTask = refStorage.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update User Provider
      await ref.read(userProvider.notifier).updateProfileImage(downloadUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 100,
        ),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: user.profileImageUrl.startsWith('http')
                      ? NetworkImage(user.profileImageUrl)
                      : AssetImage(user.profileImageUrl) as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: _isUploadingImage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
            title: const Text('Activar Notificaciones'),
            subtitle: const Text('Recibir alertas de premios, bonos y eventos'),
            value: user.notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                // Request notification permission
                final status = await Permission.notification.request();

                if (status.isGranted) {
                  ref
                      .read(userProvider.notifier)
                      .updateNotificationsEnabled(true);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Notificaciones activadas'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else if (status.isDenied) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⚠️ Permiso de notificaciones denegado'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else if (status.isPermanentlyDenied) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          '⚠️ Debes habilitar notificaciones en Configuración'),
                      action: SnackBarAction(
                        label: 'Abrir',
                        onPressed: () => openAppSettings(),
                      ),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              } else {
                // Just disable in preferences
                ref
                    .read(userProvider.notifier)
                    .updateNotificationsEnabled(false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificaciones desactivadas'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          SwitchListTile(
            title: Row(
              children: [
                const Flexible(
                  child: Text(
                    'Seguimiento de Ubicación',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (user.locationTrackingEnabled) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'ACTIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            subtitle: const Text(
                'Detectar automáticamente cuando visitas un casino para desbloquear logros (funciona en segundo plano)'),
            value: user.locationTrackingEnabled,
            onChanged: (value) async {
              if (value) {
                // Solicitar permisos de ubicación
                try {
                  // Removed legacy updateLocationTrackingEnabled call
                  if (!mounted) return;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '✅ GPS activado - Funciona incluso con la app cerrada'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                  // Verificar si solo se concedió permiso whileInUse y guiar al usuario
                  await _ensureContinuousLocationPermission();
                } catch (e) {
                  // ...
                }
              } else {
                // Removed legacy updateLocationTrackingEnabled call
                if (!mounted) return;
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Seguimiento de ubicación desactivado'),
                    ),
                  );
                }
              }
            },
          ),
          if (user.isAdmin) ...[
            const Divider(),
            _buildSectionHeader('Administración'),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Gestionar Casinos'),
              subtitle: const Text('Agregar, editar o eliminar casinos'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/admin/casinos');
              },
            ),
            ListTile(
              leading: const Icon(Icons.games),
              title: const Text('Configurar Juegos'),
              subtitle: const Text('Horarios, niveles y disponibilidad'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push('/admin/games');
              },
            ),
          ],
          if (user.locationTrackingEnabled) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Verificar Ubicación GPS'),
              subtitle: const Text('Ver distancia a casinos cercanos'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _testGPSLocation(context),
            ),
          ],
          const Divider(),
          _buildSectionHeader('Seguridad'),
          SwitchListTile(
            title: const Text('Bloqueo de Aplicación'),
            subtitle: const Text('Solicitar huella/PIN al abrir la app'),
            secondary: const Icon(Icons.fingerprint),
            activeThumbColor: AppTheme.kPrimaryBlue,
            value: ref.watch(authProvider).biometricEnabled,
            onChanged: (value) async {
              debugPrint('🔐 Biometric switch changed to: $value');
              if (value) {
                final messenger = ScaffoldMessenger.of(context);
                debugPrint('🔐 Calling enableBiometric...');
                final success =
                    await ref.read(authProvider.notifier).enableBiometric();
                debugPrint('🔐 enableBiometric returned: $success');
                if (!success) {
                  messenger.showSnackBar(
                    const SnackBar(
                        content: Text('No se pudo activar la biometría')),
                  );
                }
              } else {
                debugPrint('🔐 Calling disableBiometric...');
                await ref.read(authProvider.notifier).disableBiometric();
              }
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

  Future<void> _testGPSLocation(BuildContext context) async {
    try {
      // Mostrar diálogo de carga
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();
      final casinos = await ref.read(casinosProvider.future);

      // Cerrar diálogo de carga
      if (!context.mounted) return;
      Navigator.pop(context);

      // Calcular distancias
      final distances = casinos.map((casino) {
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          casino.latitud,
          casino.longitud,
        );
        return MapEntry(casino, distance);
      }).toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // Mostrar resultado
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📍 Tu Ubicación GPS'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lat: ${position.latitude.toStringAsFixed(4)}'),
                Text('Lon: ${position.longitude.toStringAsFixed(4)}'),
                const Divider(height: 20),
                const Text('Distancia a casinos:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...distances.map((entry) {
                  final casino = entry.key;
                  final distanceMeters = entry.value;
                  final distanceKm = distanceMeters / 1000;
                  final isNear = distanceMeters <= 200;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isNear ? Icons.check_circle : Icons.circle_outlined,
                          color: isNear ? Colors.green : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            casino.nombre,
                            style: TextStyle(
                              fontWeight:
                                  isNear ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          distanceKm < 1
                              ? '${distanceMeters.toInt()}m'
                              : '${distanceKm.toStringAsFixed(1)}km',
                          style: TextStyle(
                            color: isNear ? Colors.green : Colors.grey,
                            fontWeight:
                                isNear ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si existe
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
