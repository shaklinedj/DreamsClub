import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:casinoloyalty_flutter/screens/auth/login_screen.dart';
import 'package:casinoloyalty_flutter/screens/auth/biometric_lock_screen.dart';
import 'package:casinoloyalty_flutter/screens/splash_screen.dart';
import 'package:casinoloyalty_flutter/screens/feed/feed_screen.dart';
import 'package:casinoloyalty_flutter/screens/feed/post_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/benefits_screen.dart';
import 'package:casinoloyalty_flutter/screens/settings_screen.dart';
import 'package:casinoloyalty_flutter/screens/coyhaique/coyhaique_shell.dart';
import 'package:casinoloyalty_flutter/screens/achievements_screen.dart';
import 'package:casinoloyalty_flutter/screens/all_casinos_screen.dart';
import 'package:casinoloyalty_flutter/screens/casino_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/home_screen.dart';
import 'package:casinoloyalty_flutter/screens/spin_wheel_screen.dart';
import 'package:casinoloyalty_flutter/screens/slot_machine_screen.dart';
import 'package:casinoloyalty_flutter/screens/games/match_game_screen.dart';
import 'package:casinoloyalty_flutter/screens/notification_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/my_prizes_screen.dart';
import 'package:casinoloyalty_flutter/screens/prize_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/in_app_webview_screen.dart';

final coyhaiqueRootNavigatorKey = GlobalKey<NavigatorState>();

class AuthRouterNotifier extends ChangeNotifier {
  final Ref _ref;
  AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous == null ||
          previous.status != next.status ||
          previous.requiresBiometric != next.requiresBiometric) {
        notifyListeners();
      }
    });
  }
}

final coyhaiqueRouterProvider = Provider<GoRouter>((ref) {
  final notifier = AuthRouterNotifier(ref);

  return GoRouter(
    navigatorKey: coyhaiqueRootNavigatorKey,
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      // Interceptar deep links de esquema personalizado dreamsclub://
      if (state.uri.scheme == 'dreamsclub') {
        if (state.uri.host == 'post') {
          final postId = state.uri.path.replaceFirst('/', '');
          if (postId.isNotEmpty) {
            return '/post/$postId';
          }
        }
        if (state.uri.host == 'home') {
          return '/feed';
        }
      }

      final authState = ref.read(authProvider);
      final isLoggingIn = state.uri.path == '/login';
      final isSplash = state.uri.path == '/';
      final isBiometricLock = state.uri.path == '/biometric-lock';

      if (authState.biometricEnabled &&
          authState.requiresBiometric &&
          authState.firebaseUser != null) {
        if (!isBiometricLock) return '/biometric-lock';
        return null;
      }

      if (authState.status == AuthStatus.unknown) return null;

      if (!authState.isAuthenticated) {
        if (isSplash) return null;
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn || isSplash) {
        return '/feed';
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CoyhaiqueShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 0: Feed Social (Inicio)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          // Tab 1: Juegos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 2: Logros (Rachas y Stickers)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
            ],
          ),
          // Tab 3: Casinos
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/casinos',
                builder: (context, state) => const AllCasinosScreen(),
              ),
              GoRoute(
                path: '/all-casinos/:id',
                builder: (context, state) {
                  final casinoId = state.pathParameters['id'] ?? '';
                  return CasinoDetailScreen(casinoId: casinoId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/promos',
        builder: (context, state) => const BenefitsScreen(),
      ),
      GoRoute(
        path: '/benefits',
        builder: (context, state) => const BenefitsScreen(),
      ),
      GoRoute(
        path: '/post-detail/:id',
        builder: (context, state) {
          final postId = state.pathParameters['id'] ?? '';
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/post/:id',
        builder: (context, state) {
          final postId = state.pathParameters['id'] ?? '';
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/spin-wheel',
        builder: (context, state) => const SpinWheelScreen(),
      ),
      GoRoute(
        path: '/slot-machine',
        builder: (context, state) => const SlotMachineScreen(),
      ),
      GoRoute(
        path: '/match-game',
        builder: (context, state) => const MatchGameScreen(),
      ),
      GoRoute(
        path: '/notification-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return NotificationDetailScreen(notificationId: id);
        },
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
        path: '/webview',
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? 'https://dreams.cl';
          final title = state.uri.queryParameters['title'] ?? 'Sitio Web';
          return InAppWebViewScreen(url: url, title: title);
        },
      ),
    ],
  );
});
