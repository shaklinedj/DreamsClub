import 'dart:async';
import 'package:casinoloyalty_flutter/services/firebase_service.dart';
// import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:casinoloyalty_flutter/navigation/coyhaique_router.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:casinoloyalty_flutter/providers/gamification_provider.dart';
import 'package:casinoloyalty_flutter/services/notification_service.dart';
import 'package:casinoloyalty_flutter/services/real_notification_service.dart';
import 'package:casinoloyalty_flutter/services/background_service_impl.dart';
import 'package:casinoloyalty_flutter/services/messaging_service.dart';
import 'package:casinoloyalty_flutter/widgets/global_confetti_widget.dart';

// Nuevos imports para mejoras
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:casinoloyalty_flutter/core/services/analytics_service.dart';
import 'package:casinoloyalty_flutter/core/services/crashlytics_service.dart';

// import 'package:casinoloyalty_flutter/services/firebase_service.dart'; // Comentado para trabajar con datos mock

void main() async {
  // Capturar errores de la zona
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configurar manejo global de errores de Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (!kDebugMode) {
        // En producción, reportar a Crashlytics
        CrashlyticsService.recordError(
          details.exception,
          details.stack,
          reason: details.exceptionAsString(),
          fatal: true,
        );
      }
      AppLogger.fatal('Flutter Error', details.exception, details.stack);
    };

    // Capturar errores asíncronos no manejados
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.fatal('Unhandled Error', error, stack);
      if (!kDebugMode) {
        CrashlyticsService.recordError(error, stack, fatal: true);
      }
      return true;
    };

    AppLogger.info('🚀 Iniciando Dreams Club...');

    // Inicializar Firebase Core obligatoriamente antes de la UI
    await FirebaseService.initialize();
    AppLogger.info('✅ Firebase Core inicializado');

    // Renderizar la UI inmediatamente
    runApp(const ProviderScope(child: DreamsLoyaltyApp()));

    // Inicializaciones secundarias en segundo plano (sin congelar el inicio)
    Future.microtask(() async {
      await Future.wait([
        initializeDateFormatting('es_ES', null),
        _initializeTimezone(),
      ]);

      await _initializeFirebaseServices();

      await NotificationService.initialize();
      await MessagingService.initialize();

      NotificationService.onNotificationTap = (payload) {
        if (payload == null || payload.isEmpty) {
          coyhaiqueRootNavigatorKey.currentContext?.go('/feed');
          return;
        }
        if (payload.startsWith('/')) {
          coyhaiqueRootNavigatorKey.currentContext?.go(payload);
          return;
        }
        coyhaiqueRootNavigatorKey.currentContext?.go('/feed');
      };

      await BackgroundServiceImpl.initialize();
      AppLogger.info('✅ Servicios secundarios inicializados en segundo plano');
    });
  }, (error, stack) {
    // Captura errores de la zona
    AppLogger.fatal('Zone Error', error, stack);
    if (!kDebugMode) {
      CrashlyticsService.recordError(error, stack, fatal: true);
    }
  });
}

/// Inicializa timezone para notificaciones programadas.
Future<void> _initializeTimezone() async {
  tz.initializeTimeZones();
  AppLogger.debug('Timezone inicializado');
}

/// Inicializa servicios adicionales de Firebase en segundo plano (AppCheck, Crashlytics, Analytics).
Future<void> _initializeFirebaseServices() async {
  try {
    /*
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      webProvider: ReCaptchaEnterpriseProvider('recaptcha-site-key'),
    );
    */
    AppLogger.info('✅ Firebase App Check inicializado');

    if (!kIsWeb) {
      await CrashlyticsService.initialize();
      AppLogger.info('✅ Crashlytics inicializado');
      await AnalyticsService.initialize();
      AppLogger.info('✅ Analytics inicializado');
    }
  } catch (e, stack) {
    AppLogger.error('Error inicializando Firebase services secundarios', e, stack);
  }
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Widget principal de la aplicación.
class DreamsLoyaltyApp extends ConsumerWidget {
  const DreamsLoyaltyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializar notificaciones reales
    ref.watch(realNotificationServiceProvider);

    final appRouter = ref.watch(coyhaiqueRouterProvider);
    final streakData = ref.watch(streakProvider);
    final currentTheme = AppTheme.getThemeByStreak(streakData.currentStreak);

    return MaterialApp.router(
      title: 'Dreams Club',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      themeMode: ThemeMode.dark, // The gamification UI relies on dark theme
      theme: currentTheme,
      darkTheme: currentTheme,
      routerConfig: appRouter,
      // Observer de Analytics para tracking automático de navegación
      // navigatorObservers: [
      //   if (AnalyticsService.observer != null) AnalyticsService.observer!,
      // ],
      builder: (context, child) {
        // Wrapper para manejo de errores en UI y confeti global
        return _ErrorBoundary(
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const GlobalConfettiWidget(),
            ],
          ),
        );
      },
    );
  }
}

/// Boundary para capturar errores en el árbol de widgets.
class _ErrorBoundary extends StatelessWidget {
  final Widget child;

  const _ErrorBoundary({required this.child});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      AppLogger.error('UI Error', details.exception, details.stack);

      if (kDebugMode) {
        return ErrorWidget(details.exception);
      }

      // En producción, mostrar UI amigable
      return Material(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.amber[700],
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Algo salió mal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  details.exception.toString(),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Por favor, reinicia la aplicación',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    };

    return child;
  }
}
