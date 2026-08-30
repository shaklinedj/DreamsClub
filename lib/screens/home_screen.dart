import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:casinoloyalty_flutter/providers/game_availability_provider.dart';
import 'package:casinoloyalty_flutter/services/app_update_service.dart';
import 'package:casinoloyalty_flutter/widgets/dreams_mania/dreams_mania_dialog.dart';
import 'package:casinoloyalty_flutter/widgets/app_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  bool _isNewerVersion(String latest, String current) {
    try {
      final cleanLatest = latest.trim();
      final cleanCurrent = current.trim();
      if (cleanLatest == cleanCurrent) return false;

      final lParts = cleanLatest
          .split('+')[0]
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();
      final cParts = cleanCurrent
          .split('+')[0]
          .split('.')
          .map((e) => int.tryParse(e) ?? 0)
          .toList();

      for (int i = 0; i < 3; i++) {
        final l = i < lParts.length ? lParts[i] : 0;
        final c = i < cParts.length ? cParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }

      if (cleanLatest.contains('+') && cleanCurrent.contains('+')) {
        final lBuild = int.tryParse(cleanLatest.split('+')[1]) ?? 0;
        final cBuild = int.tryParse(cleanCurrent.split('+')[1]) ?? 0;
        return lBuild > cBuild;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final latestVersion = data['latestVersion']?.toString();

          if (latestVersion != null &&
              _isNewerVersion(latestVersion, currentVersion)) {
            if (!mounted) return;

            // URL directa desde GitHub Releases (única fuente)
            final directApkUrl =
                'https://github.com/shaklinedj/DreamsClub-Release/releases/download/v$latestVersion/DreamsApp-v$latestVersion.apk';

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                bool isDownloading = false;
                int progressPercentage = 0;
                String statusMessage =
                    'Hay una nueva versión de Dreams Club disponible (v$latestVersion).';
                bool hasError = false;

                return StatefulBuilder(
                  builder: (context, setDialogState) {
                    return AlertDialog(
                      backgroundColor: const Color(0xFF1E1E2C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                            color: Color(0xFFD4AF37), width: 1.5),
                      ),
                      title: Row(
                        children: [
                          const Text('🚀 ', style: TextStyle(fontSize: 20)),
                          Text(
                            isDownloading
                                ? 'Descargando Actualización'
                                : 'Actualización Disponible',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusMessage,
                            style: TextStyle(
                              color: hasError
                                  ? Colors.redAccent
                                  : Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (isDownloading && !hasError) ...[
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: progressPercentage > 0
                                  ? progressPercentage / 100.0
                                  : null,
                              backgroundColor: Colors.white10,
                              color: const Color(0xFFD4AF37),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                '$progressPercentage%',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      actions: [
                        if (!isDownloading || hasError) ...[
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              hasError ? 'Cerrar' : 'Más tarde',
                              style:
                                  const TextStyle(color: Colors.white38),
                            ),
                          ),
                          if (!hasError)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD4AF37),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                setDialogState(() {
                                  isDownloading = true;
                                  hasError = false;
                                  statusMessage =
                                      'Descargando desde GitHub... Por favor no cierres la app.';
                                });

                                AppUpdateService.instance
                                    .downloadAndInstallApk(directApkUrl)
                                    .listen(
                                  (OtaEvent event) {
                                    setDialogState(() {
                                      switch (event.status) {
                                        case OtaStatus.DOWNLOADING:
                                          progressPercentage =
                                              int.tryParse(
                                                      event.value ?? '0') ??
                                                  progressPercentage;
                                          break;
                                        case OtaStatus.INSTALLING:
                                          statusMessage =
                                              '¡Descarga completada! Abriendo instalador...';
                                          progressPercentage = 100;
                                          break;
                                        case OtaStatus.ALREADY_RUNNING_ERROR:
                                          statusMessage =
                                              'Ya hay una descarga en progreso.';
                                          break;
                                        case OtaStatus
                                            .PERMISSION_NOT_GRANTED_ERROR:
                                          hasError = true;
                                          isDownloading = false;
                                          statusMessage =
                                              'Permiso de instalación denegado. Ve a Ajustes y habilita "Instalar apps desconocidas".';
                                          break;
                                        default:
                                          if (progressPercentage >= 95) {
                                            statusMessage =
                                                'Instalando en tu dispositivo...';
                                            progressPercentage = 100;
                                          }
                                          break;
                                      }
                                    });
                                  },
                                  onError: (_) {
                                    setDialogState(() {
                                      hasError = true;
                                      isDownloading = false;
                                      statusMessage =
                                          'Error al descargar la actualización. Inténtalo más tarde.';
                                    });
                                  },
                                );
                              },
                              child: const Text(
                                'Actualizar ahora',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                );
              },
            );
          }
        }
      }
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const Text(
                    'ZONA DE JUEGOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),

              // 1. La Granja Dreams (Farmland)
              const _SmartGameLauncher(
                gameId: 'dreams_farmland',
                defaultTitle: 'LA GRANJA DREAMS',
                subtitle: '¡Riega, cultiva y gana puntos!',
                icon: Icons.agriculture_rounded,
                color: Colors.lightGreenAccent,
                imagePath: 'assets/images/games/farmland_bg.png',
                route: '/farmland',
              ),
              const SizedBox(height: 14),

              // 2. Dreams Mania
              _SmartGameLauncher(
                gameId: 'dreams_mania',
                defaultTitle: 'DREAMS MANÍA',
                subtitle: '¡Gana premios increíbles!',
                icon: Icons.star_rate_rounded,
                color: Colors.purpleAccent,
                imagePath: 'assets/images/games/dreams_mania_bg.png',
                route: '/dreams-mania',
                onCustomTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => const DreamsManiaDialog(),
                  );
                },
              ),
              const SizedBox(height: 14),

              // 3. Ruleta de la Suerte
              const _SmartGameLauncher(
                gameId: 'roulette',
                defaultTitle: 'RULETA DE LA SUERTE',
                subtitle: 'Prueba tu suerte hoy',
                icon: Icons.casino_rounded,
                color: Colors.tealAccent,
                imagePath: 'assets/images/games/roulette_bg.png',
                route: '/spin-wheel',
              ),
              const SizedBox(height: 14),

              // 4. Máquina de Premios (Slots)
              const _SmartGameLauncher(
                gameId: 'slots',
                defaultTitle: 'MÁQUINA DE PREMIOS',
                subtitle: 'Slots y diversión',
                icon: Icons.games_rounded,
                color: Colors.amberAccent,
                imagePath: 'assets/images/games/slots_bg.png',
                route: '/slot-machine',
              ),
              const SizedBox(height: 14),

              // 5. Dreams Match (Gemas)
              const _SmartGameLauncher(
                gameId: 'dreams_match',
                defaultTitle: 'DREAMS MATCH',
                subtitle: 'Combina gemas y gana premios',
                icon: Icons.grid_view_rounded,
                color: Colors.blueAccent,
                imagePath: 'assets/images/games/match_bg.png',
                route: '/match-game',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmartGameLauncher extends ConsumerWidget {
  final String gameId;
  final String defaultTitle;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String imagePath;
  final String route;
  final VoidCallback? onCustomTap;

  const _SmartGameLauncher({
    required this.gameId,
    required this.defaultTitle,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.imagePath,
    required this.route,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(gameAvailabilityProvider(gameId));

    if (availability.status == GameStatus.available) {
      return _GameLauncherCard(
        title: availability.config.title.isNotEmpty
            ? availability.config.title
            : defaultTitle,
        subtitle: subtitle,
        icon: icon,
        color: color,
        imagePath: imagePath,
        onTap: onCustomTap ?? () => context.push(route),
      );
    }

    return _LockedGameCard(
      title: availability.config.title.isNotEmpty
          ? availability.config.title
          : defaultTitle,
      reason: availability.message ?? 'No disponible',
    );
  }
}

class _GameLauncherCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? imagePath;
  final VoidCallback onTap;

  const _GameLauncherCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(18)),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 36),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.arrow_forward_ios,
                  color: Colors.white38, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedGameCard extends StatelessWidget {
  final String title;
  final String? reason;

  const _LockedGameCard({required this.title, this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white38, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white38, fontWeight: FontWeight.bold),
                ),
                if (reason != null)
                  Text(
                    reason!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
