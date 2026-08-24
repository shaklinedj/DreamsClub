import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:dio/dio.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditingName = false;
  bool _isEditingPhone = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController.text = user.name;
    _phoneController.text = user.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2230),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.amber),
              title: const Text('Elegir de la Galería', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _executePickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.amber),
              title: const Text('Tomar Foto con la Cámara', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _executePickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.redAccent),
              title: const Text('Restablecer Logo Dreams por Defecto', style: TextStyle(color: Colors.white70)),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(userProvider.notifier).updateProfileImage('assets/images/logo-dreams.png');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto de perfil restablecida')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executePickAndUpload(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      String cloudUrl = '';

      // Convert to Base64
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64String = base64Encode(bytes);
      final mimeType = 'image/jpeg';
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to Google Drive via Vercel API
      try {
        final dio = Dio();
        final response = await dio.post(
          'https://dreams-club.vercel.app/api/upload',
          data: {
            'base64Image': 'data:$mimeType;base64,$base64String',
            'fileName': fileName,
            'mimeType': mimeType,
          },
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          )
        );

        if (response.statusCode == 200 && response.data['success'] == true) {
          cloudUrl = response.data['url'];
        } else {
          throw Exception('Error en respuesta del servidor: ${response.data}');
        }
      } catch (uploadError) {
        AppLogger.error('Error uploading to Vercel/GDrive', uploadError);
        // Fallback a Base64 local si el servidor falla o no está configurado aún
        cloudUrl = 'data:$mimeType;base64,$base64String';
      }

      // Update User Provider
      await ref.read(userProvider.notifier).updateProfileImage(cloudUrl);

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

  ImageProvider _resolveAvatar(String path) {
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
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
                  backgroundImage: _resolveAvatar(user.profileImageUrl),
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
          if (user.rut != null && user.rut!.isNotEmpty)
            ListTile(
              title: const Text('RUT'),
              subtitle: Text(user.rut!),
              trailing: const Icon(Icons.badge_outlined, size: 16),
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
          SwitchListTile(
            title: const Text('Deseo ser contactado'),
            subtitle: const Text('Permitir que personal de Dreams me contacte'),
            value: user.wantsContact,
            activeThumbColor: AppTheme.kPrimaryBlue,
            onChanged: (value) {
              ref.read(userProvider.notifier).updateProfileDetails(
                name: user.name,
                wantsContact: value,
                phoneNumber: user.phoneNumber,
              );
            },
          ),
          if (user.wantsContact)
            ListTile(
              title: const Text('Número de Teléfono'),
              subtitle: _isEditingPhone
                  ? TextField(
                      controller: _phoneController,
                      autofocus: true,
                      keyboardType: TextInputType.phone,
                      onSubmitted: (value) {
                        ref.read(userProvider.notifier).updateProfileDetails(
                          name: user.name,
                          wantsContact: user.wantsContact,
                          phoneNumber: value,
                        );
                        setState(() {
                          _isEditingPhone = false;
                        });
                      },
                    )
                  : Text(user.phoneNumber?.isNotEmpty == true ? user.phoneNumber! : 'No configurado'),
              trailing: IconButton(
                icon: Icon(_isEditingPhone ? Icons.check : Icons.edit),
                onPressed: () {
                  if (_isEditingPhone) {
                    ref.read(userProvider.notifier).updateProfileDetails(
                      name: user.name,
                      wantsContact: user.wantsContact,
                      phoneNumber: _phoneController.text,
                    );
                    setState(() {
                      _isEditingPhone = false;
                    });
                  } else {
                    setState(() {
                      _isEditingPhone = true;
                    });
                  }
                },
              ),
            ),
          const Divider(),
          _buildSectionHeader('Preferencias'),
          const ListTile(
            leading: Icon(Icons.location_city, color: Color(0xFFD4AF37)),
            title: Text('Casino Principal'),
            subtitle: Text('Dreams Coyhaique (Patagonia)'),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: 20),
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
}
