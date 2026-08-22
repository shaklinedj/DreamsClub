import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casinoloyalty_flutter/widgets/animated_bell.dart';
import 'package:casinoloyalty_flutter/widgets/notifications_modal.dart';
import 'package:casinoloyalty_flutter/providers/game_availability_provider.dart';
import 'package:casinoloyalty_flutter/screens/coyhaique/coyhaique_shell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Dreams Mania Imports
import 'package:casinoloyalty_flutter/services/dreams_mania_service.dart';
import 'package:casinoloyalty_flutter/widgets/dreams_mania/dreams_mania_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PrizeService _prizeService = PrizeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      const currentVersion = "1.0.1";
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('app')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final latestVersion = data['latestVersion']?.toString();
          final downloadUrl = data['downloadUrl']?.toString() ?? 'https://dreams-casino-app.web.app/download';
          
          if (latestVersion != null && latestVersion != currentVersion) {
            if (!mounted) return;
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: const Color(0xFF1E1E2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                  ),
                  title: const Row(
                    children: [
                      Text('🚀 ', style: TextStyle(fontSize: 20)),
                      Text(
                        'Actualización',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    'Hay una nueva versión de Dreams Club disponible (v$latestVersion). Descárgala para disfrutar de las últimas mejoras y correcciones.',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Más tarde',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        final uri = Uri.parse(downloadUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: const Text(
                        'Actualizar Ahora',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    } catch (e) {
      // Ignorar errores silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userId = user.email.isNotEmpty ? user.email : (user.rut ?? '');

    return Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Image.asset(
            'assets/images/logo-dreams.png',
            height: 50,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 1,
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              CoyhaiqueShell.openDrawer();
            },
          ),
          actions: [
            Center(
              child: GestureDetector(
                onTap: () => context.push('/my-prizes'),
                child: StreamBuilder<List<WonPrize>>(
                  stream: _prizeService.streamUserPrizes(userId),
                  builder: (context, snapshot) {
                    final activeCount = snapshot.data?.where((p) => p.isActive).length ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2A2A3E), Color(0xFF1E1E2C)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎁', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 5),
                          const Text(
                            'Mis Premios',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (activeCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$activeCount',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const AnimatedBell(),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const NotificationsModal(),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient:
                AppTheme.backgroundGradient(Theme.of(context).colorScheme),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ZONA DE JUEGOS
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZONA DE JUEGOS',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Dreams Mania
                    _SmartGameLauncher(
                      gameId: 'dreams_mania',
                      defaultTitle: 'DREAMS MANÍA',
                      subtitle: '¡Gana premios increíbles!',
                      icon: Icons.star_rate_rounded, // Placeholder icon
                      color: Colors.purpleAccent,
                      imagePath:
                          'assets/images/games/dreams_mania_bg.png',
                      route:
                          '/dreams-mania', // Ignored if onCustomTap is set
                      onCustomTap: () {
                        ref
                            .read(dreamsManiaProvider.notifier)
                            .triggerEvent();
                        showDialog(
                          context: context,
                          builder: (_) => const DreamsManiaDialog(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ruleta
                    const _SmartGameLauncher(
                      gameId: 'roulette',
                      defaultTitle: 'RULETA DE LA SUERTE',
                      subtitle: 'Prueba tu suerte hoy',
                      icon: Icons.casino_rounded,
                      color: Colors.tealAccent,
                      imagePath: 'assets/images/games/roulette_bg.png',
                      route: '/spin-wheel', // Correct route
                    ),
                    const SizedBox(height: 16),

                    const _SmartGameLauncher(
                      gameId: 'slots',
                      defaultTitle: 'MÁQUINA DE PREMIOS',
                      subtitle: 'Slots y diversión',
                      icon: Icons.games_rounded,
                      color: Colors.amberAccent,
                      imagePath: 'assets/images/games/slots_bg.png',
                      route: '/slot-machine',
                    ),
                    const SizedBox(height: 16),
                    // Dreams Match (Gemas)
                    const _SmartGameLauncher(
                      gameId: 'dreams_match',
                      defaultTitle: 'DREAMS MATCH',
                      subtitle: 'Combina gemas y gana premios',
                      icon: Icons.grid_view_rounded,
                      color: Colors.blueAccent,
                      imagePath: 'assets/images/games/match_bg.png',
                      route: '/match-game',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
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

    // Si está disponible, mostramos la carta activa
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

    // Si no, mostramos carta bloqueada con la razón
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
  final String? imagePath; // Optional background image
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
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              Colors.black.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon / Image Section
            Container(
              width: 80,
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 32),
              ),
            ),

            // Text Section
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
                        fontWeight: FontWeight.w800,
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

            // Arrow
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.arrow_forward_ios,
                  color: Colors.white30, size: 16),
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
      height: 70, // Slightly taller to fit reason
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white38, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white38, fontWeight: FontWeight.bold)),
                if (reason != null)
                  Text(reason!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
