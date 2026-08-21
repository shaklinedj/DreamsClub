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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
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
                          if (casino.reservationUrl != null && casino.reservationUrl!.isNotEmpty)
                            _ActionCard(
                              icon: Icons.hotel,
                              title: 'Reservar Hotel',
                              subtitle: 'Alojamiento Dreams',
                              color: Colors.blue,
                              onTap: () => _openHotelReservation(context, casino),
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
                          // Website Card
                          _ActionCard(
                            icon: Icons.language,
                            title: 'Sitio Web',
                            subtitle: 'dreams.cl',
                            color: Colors.teal,
                            onTap: () => _openCasinoWeb(context, casino),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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
      await mapService.showMapMarker(
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

  void _openHotelReservation(BuildContext context, Casino casino) {
    final reservationUrl = casino.reservationUrl;
    if (reservationUrl == null || reservationUrl.isEmpty) return;
    
    final uri = Uri(
      path: '/webview',
      queryParameters: {
        'url': reservationUrl,
        'title': 'Reservar Hotel',
      },
    );
    context.push(uri.toString());
  }

  String _getScheduleSummary(Casino casino) {
    if (casino.schedules == null || casino.schedules!.isEmpty) {
      return 'Consultar horarios';
    }
    final firstEntry = casino.schedules!.entries.first;
    return '${firstEntry.key}: ${firstEntry.value}';
  }

  void _showHours(BuildContext context, Casino casino) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2230),
        title: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Horarios ${casino.nombre}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (casino.schedules != null && casino.schedules!.isNotEmpty)
              ...casino.schedules!.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        entry.value,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text(
                'Abierto las 24 horas todos los días',
                style: TextStyle(color: Colors.white70),
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
                try {
                  await launchUrl(url);
                } catch (_) {}
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('contacto@dreams.cl'),
              onTap: () async {
                final url = Uri.parse('mailto:contacto@dreams.cl');
                try {
                  await launchUrl(url);
                } catch (_) {}
                if (context.mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Sitio Web'),
              subtitle: const Text('dreams.cl'),
              onTap: () async {
                final url = Uri.parse('https://dreams.cl');
                try {
                  await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                } catch (_) {
                  try {
                    await launchUrl(url, mode: LaunchMode.platformDefault);
                  } catch (_) {}
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

  void _openCasinoWeb(BuildContext context, Casino casino) {
    final websiteUrl = casino.websiteUrl ?? 'https://dreams.cl';
    final uri = Uri(
      path: '/webview',
      queryParameters: {
        'url': websiteUrl,
        'title': 'Sitio Web - ${casino.nombre}',
      },
    );
    context.push(uri.toString());
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
