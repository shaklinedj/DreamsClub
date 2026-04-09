import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:casinoloyalty_flutter/widgets/glass_container.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Banner que incentiva al usuario a activar permisos de ubicación "siempre activo"
/// para aprovechar funcionalidades como detección de casino en segundo plano,
/// Dreams Mania, Slot y gamificación.
class LocationUpgradeBanner extends StatefulWidget {
  const LocationUpgradeBanner({super.key});

  @override
  State<LocationUpgradeBanner> createState() => _LocationUpgradeBannerState();
}

class _LocationUpgradeBannerState extends State<LocationUpgradeBanner> {
  bool _shouldShow = false;
  bool _dismissed = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    // Verificar si el usuario ya descartó permanentemente el banner
    final prefs = await SharedPreferences.getInstance();
    final permanentlyDismissed =
        prefs.getBool('location_upgrade_dismissed') ?? false;

    if (permanentlyDismissed) {
      return;
    }

    // Verificar el estado actual del permiso
    final permission = await Geolocator.checkPermission();

    if (mounted) {
      setState(() {
        // Solo mostrar si tiene whileInUse pero NO always
        _shouldShow = permission == LocationPermission.whileInUse;
      });
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
    // Después de volver de la configuración, verificar el nuevo estado
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkPermissionStatus();
  }

  void _dismiss() {
    setState(() {
      _dismissed = true;
    });
  }

  Future<void> _dismissPermanently() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_upgrade_dismissed', true);
    if (mounted) {
      setState(() {
        _shouldShow = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow || _dismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        opacity: 0.15,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.black,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Desbloquea más beneficios!',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Activa ubicación siempre activa',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),

            // Expanded content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 16),

                  // Benefits list
                  const _BenefitItem(
                    icon: Icons.notifications_active,
                    title: 'Alertas de casino cercano',
                    description:
                        'Te avisamos cuando estés cerca de tu casino, incluso con la app cerrada',
                  ),
                  const SizedBox(height: 10),
                  const _BenefitItem(
                    icon: Icons.casino,
                    title: 'Dreams Mania & Slots',
                    description:
                        'Juega Dreams Mania o la máquina de slots cuando llegues al casino',
                  ),
                  const SizedBox(height: 10),
                  const _BenefitItem(
                    icon: Icons.emoji_events,
                    title: 'Gamificación completa',
                    description:
                        'Desbloquea logros y misiones automáticamente al visitar casinos',
                  ),
                  const SizedBox(height: 10),
                  const _BenefitItem(
                    icon: Icons.star,
                    title: 'Puntos bonus',
                    description:
                        'Acumula puntos Dreams extra por cada visita detectada',
                  ),

                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _dismiss,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Ahora no'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _openSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.settings, size: 18),
                              SizedBox(width: 8),
                              Text('Activar ahora'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Dismiss permanently option
                  Center(
                    child: TextButton(
                      onPressed: _dismissPermanently,
                      child: Text(
                        'No volver a mostrar',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ),
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

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
