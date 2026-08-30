import 'package:casinoloyalty_flutter/screens/feed/feed_screen.dart';

import 'package:casinoloyalty_flutter/screens/feed/post_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/qr_scanner_screen.dart';
import 'package:casinoloyalty_flutter/screens/achievements_screen.dart';
import 'package:casinoloyalty_flutter/screens/all_casinos_screen.dart';
import 'package:casinoloyalty_flutter/screens/casino_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/splash_screen.dart';
import 'package:casinoloyalty_flutter/screens/home_screen.dart';
import 'package:casinoloyalty_flutter/screens/wallet_screen.dart';
import 'package:casinoloyalty_flutter/screens/my_prizes_screen.dart';
import 'package:casinoloyalty_flutter/screens/prize_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/select_favorite_screen.dart';
import 'package:casinoloyalty_flutter/screens/settings_screen.dart';
import 'package:casinoloyalty_flutter/screens/benefits_screen.dart';
import 'package:casinoloyalty_flutter/screens/slot_machine_screen.dart';
import 'package:casinoloyalty_flutter/screens/spin_wheel_screen.dart';
import 'package:casinoloyalty_flutter/screens/games/match_game_screen.dart';
import 'package:casinoloyalty_flutter/screens/games/farmland_game_screen.dart';
import 'package:casinoloyalty_flutter/screens/admin/admin_casinos_screen.dart';
import 'package:casinoloyalty_flutter/screens/admin/casino_form_screen.dart';
import 'package:casinoloyalty_flutter/screens/admin/admin_games_screen.dart';
import 'package:casinoloyalty_flutter/screens/admin/game_config_form_screen.dart';
import 'package:casinoloyalty_flutter/screens/auth/login_screen.dart';
import 'package:casinoloyalty_flutter/screens/auth/biometric_lock_screen.dart';
import 'package:casinoloyalty_flutter/models/casino_model.dart';
import 'package:casinoloyalty_flutter/models/game_config_model.dart';

import 'package:casinoloyalty_flutter/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;
  AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = AuthRouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggingIn = state.uri.path == '/login';
      final isSplash = state.uri.path == '/';
      final isBiometricLock = state.uri.path == '/biometric-lock';

      // Bloqueo biométrico obligatorio - PRIMERO antes de cualquier otra cosa
      if (authState.biometricEnabled &&
          authState.requiresBiometric &&
          !isBiometricLock) {
        return '/biometric-lock';
      }

      // Permitir acceso a Splash para inicialización
      if (isSplash) return null;

      // Si está autenticado y intenta ir a login, enviar a home
      final isLoggedIn = authState.status == AuthStatus.authenticated;
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/biometric-lock',
        builder: (context, state) => const BiometricLockScreen(),
      ),
      GoRoute(
        path: '/select-favorite',
        builder: (context, state) => const SelectFavoriteScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/benefits',
        builder: (context, state) => const BenefitsScreen(),
      ),
      GoRoute(
        path: '/slot-machine',
        builder: (context, state) => const SlotMachineScreen(),
      ),
      GoRoute(
        path: '/my-prizes',
        builder: (context, state) => const MyPrizesScreen(),
      ),
      GoRoute(
        path: '/prize-detail/:id',
        builder: (context, state) {
          final prizeId = state.pathParameters['id']!;
          return PrizeDetailScreen(prizeId: prizeId);
        },
      ),
      GoRoute(
        path: '/spin-wheel',
        builder: (context, state) => const SpinWheelScreen(),
      ),
      GoRoute(
        path: '/match-game',
        builder: (context, state) => const MatchGameScreen(),
      ),
      GoRoute(
        path: '/farmland',
        builder: (context, state) => const FarmlandGameScreen(),
      ),

      GoRoute(
        path: '/post/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) {
                  return const FeedScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/all-casinos',
                builder: (context, state) => const AllCasinosScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final casinoId = state.pathParameters['id']!;
                      return CasinoDetailScreen(casinoId: casinoId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/admin/casinos',
        builder: (context, state) => const AdminCasinosScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CasinoFormScreen(),
          ),
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final casino = state.extra as Casino?;
              return CasinoFormScreen(casino: casino);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/games',
        builder: (context, state) => const AdminGamesScreen(),
        routes: [
          GoRoute(
            path: 'edit/:id',
            builder: (context, state) {
              final config = state.extra as GameConfig?;
              return GameConfigFormScreen(config: config);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QRScannerScreen(),
      ),
    ],
  );
});
