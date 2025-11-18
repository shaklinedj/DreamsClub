import 'dart:io';
import 'dart:ui';

import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/background_distance_service.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';
import 'package:casinoloyalty_flutter/widgets/loyalty_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _isSavingName = false;
  bool _isUpdatingPhoto = false;
  bool _distanceNotificationsEnabled = false;
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

    setState(() => _isSavingName = true);
    try {
      await ref.read(userProvider.notifier).updateName(name);
      _showSnackBar('Nombre actualizado.');
    } catch (e) {
      _showSnackBar('No se pudo guardar el nombre. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isUpdatingPhoto = true);
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
    } finally {
      if (mounted) {
        setState(() => _isUpdatingPhoto = false);
      }
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleDistanceNotifications(bool value) async {
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;

        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.go('/home');
        }
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        backgroundColor: colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Mi Perfil'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final router = GoRouter.of(context);
                  if (router.canPop()) {
                    router.pop();
                  } else {
                    router.go('/home');
                  }
                },
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _ProfileHeaderDelegate(
                user: user,
                avatarImage: _buildProfileImage(user.profileImageUrl),
                isUpdating: _isUpdatingPhoto,
                onEditPhoto: _isUpdatingPhoto ? null : _showPhotoOptions,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre completo',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSavingName ? null : _saveName,
                        icon: _isSavingName
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Guardar nombre'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LoyaltyCardWidget(user: user, compact: true),
                    const SizedBox(height: 24),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: Text(user.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Configuración',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: SwitchListTile(
                        secondary: const Icon(Icons.notifications_active_outlined),
                        title: const Text('Notificaciones de distancia'),
                        subtitle: Text(
                          'Recibe una notificación cuando estés a más de ${BackgroundDistanceService.distanceThresholdKm.toInt()}km de tu casino favorito',
                        ),
                        value: _distanceNotificationsEnabled,
                        onChanged: _toggleDistanceNotifications,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProfileHeaderDelegate({
    required this.user,
    required this.avatarImage,
    required this.isUpdating,
    required this.onEditPhoto,
  });

  final User user;
  final ImageProvider avatarImage;
  final bool isUpdating;
  final VoidCallback? onEditPhoto;

  @override
  double get maxExtent => 260;

  @override
  double get minExtent => 150;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final avatarSize = lerpDouble(120, 72, t)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Color.lerp(colorScheme.surface, colorScheme.surfaceContainerHighest, 0.2),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundImage: avatarImage,
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: FloatingActionButton.small(
                      heroTag: 'edit-photo',
                      onPressed: onEditPhoto,
                      child: isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.levelName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.user != user ||
        oldDelegate.isUpdating != isUpdating ||
        oldDelegate.avatarImage != avatarImage;
  }
}
