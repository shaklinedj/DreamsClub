import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:casinoloyalty_flutter/services/firebase_service.dart';
import 'package:casinoloyalty_flutter/navigation/coyhaique_router.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:casinoloyalty_flutter/providers/gamification_provider.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.fatal('Flutter Error', details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.fatal('Unhandled Error', error, stack);
      return true;
    };

    AppLogger.info('🚀 Iniciando Dreams Coyhaique Social...');

    await Future.wait([
      initializeDateFormatting('es_ES', null),
      _initializeTimezone(),
      FirebaseService.initialize(),
    ]);

    runApp(const ProviderScope(child: CoyhaiqueSocialApp()));
  }, (error, stack) {
    AppLogger.fatal('Zone Error', error, stack);
  });
}

Future<void> _initializeTimezone() async {
  tz.initializeTimeZones();
}

class CoyhaiqueSocialApp extends ConsumerWidget {
  const CoyhaiqueSocialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(coyhaiqueRouterProvider);
    final streakData = ref.watch(streakProvider);
    final currentTheme = AppTheme.getThemeByStreak(streakData.currentStreak);

    return MaterialApp.router(
      title: 'Dreams Coyhaique Social',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: currentTheme,
      darkTheme: currentTheme,
      routerConfig: router,
    );
  }
}
