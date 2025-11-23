import 'package:casinoloyalty_flutter/navigation/app_router.dart';
import 'package:casinoloyalty_flutter/providers/theme_provider.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:casinoloyalty_flutter/services/background_distance_service.dart';
import 'package:casinoloyalty_flutter/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  await NotificationService.initialize();
  await BackgroundDistanceService.initialize(
    onNotificationResponse: (response) {
      if (response.payload == 'distance_alert') {
        // Navegar a la pantalla de decisión para re-evaluar ubicación
        appRouter.go('/');
      }
    },
  );

  runApp(const ProviderScope(child: DreamsLoyaltyApp()));
}

class DreamsLoyaltyApp extends ConsumerWidget {
  const DreamsLoyaltyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Dreams Club',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
