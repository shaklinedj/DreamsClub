
import 'package:casinoloyalty_flutter/screens/casino_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/event_detail_screen.dart';
import 'package:casinoloyalty_flutter/screens/home_screen.dart';
import 'package:casinoloyalty_flutter/screens/promotion_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'casino/:id',
          builder: (BuildContext context, GoRouterState state) {
            final String id = state.pathParameters['id']!;
            return CasinoDetailScreen(casinoId: id);
          },
        ),
         GoRoute(
          path: 'promotion/:id',
          builder: (BuildContext context, GoRouterState state) {
            final String id = state.pathParameters['id']!;
            return PromotionDetailScreen(promotionId: id);
          },
        ),
         GoRoute(
          path: 'event/:id',
          builder: (BuildContext context, GoRouterState state) {
            final String id = state.pathParameters['id']!;
            return EventDetailScreen(eventId: id);
          },
        ),
      ],
    ),
  ],
);
