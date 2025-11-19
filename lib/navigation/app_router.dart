import 'package:casinoloyalty_flutter/screens/all_casinos_screen.dart';
import 'package:casinoloyalty_flutter/screens/casino_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/decision_screen.dart';
import 'package:casinoloyalty_flutter/screens/event_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/events_screen.dart';
import 'package:casinoloyalty_flutter/screens/home_screen.dart';
import 'package:casinoloyalty_flutter/screens/promotion_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/promotions_screen.dart';
import 'package:casinoloyalty_flutter/screens/permissions_screen.dart';
import 'package:casinoloyalty_flutter/screens/profile_screen.dart';
import 'package:casinoloyalty_flutter/screens/restaurant_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/restaurants_screen.dart';
import 'package:casinoloyalty_flutter/screens/select_favorite_screen.dart';
import 'package:casinoloyalty_flutter/screens/settings_screen.dart';
import 'package:casinoloyalty_flutter/widgets/scaffold_with_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DecisionScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionsScreen(),
    ),
    GoRoute(
      path: '/select-favorite',
      builder: (context, state) => const SelectFavoriteScreen(),
    ),
    GoRoute(
      path: '/promotion/:id',
      builder: (context, state) {
        final promotionId = state.pathParameters['id']!;
        return PromotionDetailScreen(promotionId: promotionId);
      },
    ),
    GoRoute(
      path: '/event/:id',
      builder: (context, state) {
        final eventId = state.pathParameters['id']!;
        return EventDetailScreen(eventId: eventId);
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/restaurant/:id',
      builder: (context, state) {
        final restaurantId = state.pathParameters['id']!;
        return RestaurantDetailScreen(restaurantId: restaurantId);
      },
    ),
    GoRoute(
      path: '/restaurants',
      builder: (context, state) => const RestaurantsScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
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
              path: '/promotions',
              builder: (context, state) => const PromotionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventsScreen(),
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
  ],
);
