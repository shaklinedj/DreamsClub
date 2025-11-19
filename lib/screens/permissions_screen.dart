import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _gpsGranted = false;
  bool _cameraGranted = false;
  bool _photosGranted = false;
  bool _notificationsGranted = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final gps = await Permission.location.status;
    final camera = await Permission.camera.status;
    final photos = await Permission.photos.status; // Or storage depending on Android version
    final storage = await Permission.storage.status;
    final notifications = await Permission.notification.status;

    if (mounted) {
      setState(() {
        _gpsGranted = gps.isGranted;
        _cameraGranted = camera.isGranted;
        _photosGranted = photos.isGranted || storage.isGranted; // Fallback for older Android
        _notificationsGranted = notifications.isGranted;
        _checking = false;
      });

      if (_allGranted()) {
        context.go('/');
      }
    }
  }

  bool _allGranted() {
    // You can define which are mandatory. Assuming GPS and Camera are mandatory for now based on user request.
    // Photos might be optional or mandatory.
    return _gpsGranted && _cameraGranted && _notificationsGranted; 
  }

  Future<void> _requestPermission(Permission permission) async {
    await permission.request();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Permisos Necesarios',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Para brindarte la mejor experiencia, Dreams Club necesita acceso a las siguientes funcionalidades:',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _PermissionTile(
                      title: 'Ubicación (GPS)',
                      subtitle: 'Para encontrar casinos cercanos y ofertas locales.',
                      icon: Icons.location_on,
                      isGranted: _gpsGranted,
                      onTap: () => _requestPermission(Permission.location),
                    ),
                    const SizedBox(height: 16),
                    _PermissionTile(
                      title: 'Cámara',
                      subtitle: 'Para escanear códigos QR de promociones.',
                      icon: Icons.camera_alt,
                      isGranted: _cameraGranted,
                      onTap: () => _requestPermission(Permission.camera),
                    ),
                    const SizedBox(height: 16),
                    _PermissionTile(
                      title: 'Notificaciones',
                      subtitle: 'Para avisarte de sorteos y premios.',
                      icon: Icons.notifications,
                      isGranted: _notificationsGranted,
                      onTap: () => _requestPermission(Permission.notification),
                    ),
                    const SizedBox(height: 16),
                    _PermissionTile(
                      title: 'Fotos / Almacenamiento',
                      subtitle: 'Para guardar tu foto de perfil.',
                      icon: Icons.photo_library,
                      isGranted: _photosGranted,
                      onTap: () async {
                         // Handle different permissions for Android versions if needed
                         if (await Permission.photos.request().isGranted) {
                           _checkPermissions();
                         } else {
                           await Permission.storage.request();
                           _checkPermissions();
                         }
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allGranted()
                      ? () => context.go('/')
                      : null, // Disable until mandatory permissions are granted
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (!_allGranted())
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Center(
                    child: TextButton(
                      onPressed: () => context.go('/'), // Allow skip if user insists? Or maybe not.
                      child: const Text(
                        'Saltar por ahora (Algunas funciones no estarán disponibles)',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
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

class _PermissionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onTap;

  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isGranted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? Colors.green.withValues(alpha: 0.5) : Colors.white10,
        ),
      ),
      child: ListTile(
        onTap: isGranted ? null : onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isGranted ? Colors.green.withValues(alpha: 0.2) : Colors.grey[800],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isGranted ? Colors.green : Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: isGranted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
