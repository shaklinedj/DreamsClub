import 'dart:io';

import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();
  late final ProviderSubscription<User> _userSubscription;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameController = TextEditingController(text: user.name);

    _userSubscription = ref.listenManual<User>(userProvider, (prev, next) {
      if (next.name != _nameController.text) {
        _nameController.text = next.name;
      }
    });
  }

  @override
  void dispose() {
    _userSubscription.close();
    _nameController.dispose();
    super.dispose();
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

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Ingresa un nombre válido.');
      return;
    }

    try {
      await ref.read(userProvider.notifier).updateName(name);
      _showSnackBar('Nombre actualizado.');
      if (mounted) Navigator.pop(context); // Close dialog if open
    } catch (e) {
      _showSnackBar('No se pudo guardar el nombre. Intenta nuevamente.');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxHeight: 1024,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) {
        return;
      }

      final savedPath = await _persistImage(picked);
      await ref.read(userProvider.notifier).updateProfileImage(savedPath);
      _showSnackBar('Foto de perfil actualizada.');
    } catch (e) {
      _showSnackBar('No se pudo actualizar la foto. Intenta de nuevo.');
    }
  }

  Future<String> _persistImage(XFile file) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage =
        await File(file.path).copy('${directory.path}/$fileName');
    return savedImage.path;
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Restablecer imagen'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(userProvider.notifier).resetProfileImage();
                _showSnackBar('Imagen restablecida.');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _showPhotoOptions,
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _buildProfileImage(ref.read(userProvider).profileImageUrl),
                child: const Icon(Icons.camera_alt, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _saveName,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor, width: 2),
                  image: DecorationImage(
                    image: _buildProfileImage(user.profileImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('${user.levelName} Member', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              _ProfileButton(text: 'Editar Perfil', onTap: _showEditProfileDialog),
              const SizedBox(height: 8),
              _ProfileButton(text: 'Historial de Juego', onTap: () {}),
              const SizedBox(height: 8),
              _ProfileButton(
                text: 'Configuración', 
                onTap: () {
                  // Abrir drawer para configuración o navegar a pantalla de settings
                  Scaffold.of(context).openDrawer();
                }
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red[900]!.withValues(alpha: 0.3)),
                    backgroundColor: Colors.red[900]!.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cerrar Sesión', style: TextStyle(color: Colors.redAccent)),
                      Icon(Icons.logout, size: 16, color: Colors.redAccent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ProfileButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1A1A), // kSurfaceColor
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(text, style: const TextStyle(color: Colors.white)),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
