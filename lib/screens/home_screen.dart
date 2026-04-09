import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/providers/casino_providers.dart';

import 'package:casinoloyalty_flutter/widgets/favorite_casino_placeholder.dart';

import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:casinoloyalty_flutter/widgets/glass_container.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:casinoloyalty_flutter/widgets/animated_bell.dart';
import 'package:casinoloyalty_flutter/widgets/notifications_modal.dart';
import 'package:casinoloyalty_flutter/widgets/gamification_section.dart';

import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_availability_provider.dart';

import 'package:casinoloyalty_flutter/widgets/skeleton_loader.dart';
import 'package:casinoloyalty_flutter/widgets/scaffold_with_nav_bar.dart';

// Dreams Mania Imports
import 'package:casinoloyalty_flutter/services/dreams_mania_service.dart';
import 'package:casinoloyalty_flutter/widgets/dreams_mania/dreams_mania_dialog.dart';

// Match Game Imports

import 'package:casinoloyalty_flutter/services/match_game_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-launch logic removed as requested. Games are now launched manually.
  }

  @override
  Widget build(BuildContext context) {
    final selectedCasinoAsync = ref.watch(selectedCasinoProvider);
    final locationState = ref.watch(locationProvider);

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
              ScaffoldWithNavBar.scaffoldKey.currentState?.openDrawer();
            },
          ),
          actions: [
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
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: Colors.white, size: 22),
              ),
              onPressed: () => context.push('/qr-scanner'),
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
                // 1. Location Status
                if (!locationState.isLoading && !locationState.isNearAnyCasino)
                  GlassContainer(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(12),
                    opacity: 0.1,
                    child: Row(
                      children: [
                        const Icon(Icons.location_off_outlined,
                            color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Estás fuera del casino. Acércate para desbloquear los juegos.',
                            style: TextStyle(
                                color: Colors.orange[200], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Gamification Section (Misiones, Racha, Logros)
                const GamificationSection(),
                const SizedBox(height: 24),

                // 2. Casino Hero Card
                selectedCasinoAsync.when(
                  loading: () => const CasinoHeroSkeleton(),
                  error: (err, stack) => Text('Error: $err',
                      style: const TextStyle(color: Colors.red)),
                  data: (casino) {
                    if (casino == null) {
                      return _EmptyState(
                          onAction: () => context.go('/select-favorite'));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CasinoHeroCard(casino: casino),
                        const SizedBox(height: 32),

                        // 3. Games Section (Dynamic Availability)
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
                              subtitle: 'Combina gemas y gana puntos',
                              icon: Icons.grid_view_rounded,
                              color: Colors.blueAccent,
                              imagePath: 'assets/images/games/match_bg.png',
                              route: '/match-game',
                            ),
                          ],
                        ),
                      ],
                    );
                  },
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

class _CasinoHeroCard extends StatelessWidget {
  final Casino casino;
  const _CasinoHeroCard({required this.casino});

  ImageProvider _resolveImage(String url) {
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    // Assume asset
    return AssetImage(url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/all-casinos/${casino.id}'),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          image: DecorationImage(
            image: _resolveImage(casino.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.2),
              BlendMode.darken,
            ),
            onError: (exception, stackTrace) {
              // Fallback logic if needed, or handled by widget
            },
          ),
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                  stops: const [0.5, 0.8, 1.0],
                ),
              ),
            ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'CASINO FAVORITO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    casino.nombre.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          height: 1.0,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Theme.of(context).primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        casino.ciudad,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAction;
  const _EmptyState({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return FavoriteCasinoPlaceholder(onSelect: onAction);
  }
}

/// Promotional card for Match-3 game (non-members only)
class _MatchGameCard extends StatefulWidget {
  const _MatchGameCard();

  @override
  State<_MatchGameCard> createState() => _MatchGameCardState();
}

class _MatchGameCardState extends State<_MatchGameCard> {
  int _pendingPoints = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingPoints();
  }

  Future<void> _loadPendingPoints() async {
    final points = await MatchGameService.getPendingPoints();
    if (mounted) {
      setState(() {
        _pendingPoints = points;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _pendingPoints / MatchGameService.maxPendingPoints;

    return GestureDetector(
      onTap: () => context.push('/match-game'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative elements
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('💎', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DREAMS MATCH',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              '¡Juega y acumula puntos!',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 40,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Puntos Pendientes',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$_pendingPoints / ${MatchGameService.maxPendingPoints}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor:
                                const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '¡Obtén tu tarjeta Dreams para canjear tus puntos!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
