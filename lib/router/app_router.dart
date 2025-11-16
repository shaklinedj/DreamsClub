
import 'package:casinoloyalty_flutter/screens/casino_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/casino_list_screen.dart';
import 'package:casinoloyalty_flutter/screens/event_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/promotion_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/casinos',
      builder: (BuildContext context, GoRouterState state) {
        return const CasinoListScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: ':id', // Ruta anidada para detalles del casino
          builder: (BuildContext context, GoRouterState state) {
            final String id = state.pathParameters['id']!;
            return CasinoDetailScreen(casinoId: id);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/promotion/:id',
      builder: (BuildContext context, GoRouterState state) {
        final String id = state.pathParameters['id']!;
        return PromotionDetailScreen(promotionId: id);
      },
    ),
    GoRoute(
      path: '/event/:id',
      builder: (BuildContext context, GoRouterState state) {
        final String id = state.pathParameters['id']!;
        return EventDetailScreen(eventId: id);
      },
    ),
  ],
);
