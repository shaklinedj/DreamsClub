import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart'
    show casinosProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/services/map_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CasinoDetailScreen extends ConsumerStatefulWidget {
  final String casinoId;

  const CasinoDetailScreen({super.key, required this.casinoId});

  @override
  ConsumerState<CasinoDetailScreen> createState() => _CasinoDetailScreenState();
}

class _CasinoDetailScreenState extends ConsumerState<CasinoDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final String id = widget.casinoId;
    final casinoDetails = ref.watch(casinosProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Casino'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: casinoDetails.when(
        data: (casinos) {
          final Casino casino;
          try {
            casino = casinos.firstWhere((c) => c.id == id);
          } catch (e) {
            return const Center(child: Text('Casino no encontrado.'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Casino Image
                SizedBox(
                  height: 200.0,
                  width: double.infinity,
                  child: Image.asset(
                    casino.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/placeholder.jpg',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Casino Name & City
                      Text(
                        casino.nombre,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        casino.ciudad,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 20),

                      // How to Get There Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _openMaps(context, casino),
                          icon: const Icon(Icons.directions),
                          label: const Text('Cómo llegar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 4 Action Cards Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          // Hotel Card
                          _ActionCard(
                            icon: Icons.hotel,
                            title: 'Reservar Hotel',
                            subtitle: 'Alojamiento Dreams',
                            color: Colors.blue,
                            onTap: () => _openHotelReservation(casino),
                          ),
                          // Hours Card
                          _ActionCard(
                            icon: Icons.access_time,
                            title: 'Horario',
                            subtitle: _getScheduleSummary(casino),
                            color: Colors.green,
                            onTap: () => _showHours(context, casino),
                          ),
                          // Contact Card
                          _ActionCard(
                            icon: Icons.phone,
                            title: 'Contáctanos',
                            subtitle: 'Llama o escribe',
                            color: Colors.orange,
                            onTap: () => _showContactDialog(context, casino),
                          ),
                          // Feed Card
                          _ActionCard(
                            icon: Icons.video_collection,
                            title: 'Ver Feed',
                            subtitle: 'Novedades del casino',
                            color: Colors.purple,
                            onTap: () => _openCasinoFeed(context, casino),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // GPS Info Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.amber.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Los juegos y logros se activan automáticamente al visitar el casino con GPS activado.',
                                style: TextStyle(
                                  color: Colors.amber.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error al cargar el casino: $err')),
      ),
    );
  }

  Future<void> _openMaps(BuildContext context, Casino casino) async {
    try {
      final mapService = MapService();
      await mapService.openDirections(
        latitude: casino.latitud,
        longitude: casino.longitud,
        locationName: casino.nombre,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir mapas: $e')),
        );
      }
    }
  }

  void _openHotelReservation(Casino casino) async {
    // Open Dreams hotel reservation website
    final url = Uri.parse('https://dreams.cl');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _getScheduleSummary(Casino casino) {
    if (casino.schedules == null || casino.schedules!.isEmpty) {
      return 'Consultar horarios';
    }
    // Return the first schedule entry as summary
    final firstEntry = casino.schedules!.entries.first;
    return firstEntry.value;
  }

  void _showHours(BuildContext context, Casino casino) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time, color: Colors.green),
            SizedBox(width: 8),
            Text('Horario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              casino.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (casino.schedules != null && casino.schedules!.isNotEmpty)
              ...casino.schedules!.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🕐 '),
                        Expanded(
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ))
            else
              const Text('Horarios no disponibles. Consulte en el local.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(BuildContext context, Casino casino) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.contact_support, color: Colors.orange),
            SizedBox(width: 8),
            Text('Contáctanos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Llamar'),
              subtitle: const Text('+56 2 2411 0000'),
              onTap: () async {
                final url = Uri.parse('tel:+5624110000');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('contacto@dreams.cl'),
              onTap: () async {
                final url = Uri.parse('mailto:contacto@dreams.cl');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Sitio Web'),
              subtitle: const Text('dreams.cl'),
              onTap: () async {
                final url = Uri.parse('https://dreams.cl');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _openCasinoFeed(BuildContext context, Casino casino) {
    // Navigate to feed filtered by this casino
    context.push('/feed?casinoId=${casino.id}');
  }
}

// Action Card Widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
