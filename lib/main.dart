import 'dart:async';
import 'package:casinoloyalty_flutter/services/firebase_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:casinoloyalty_flutter/navigation/app_router.dart';
import 'package:casinoloyalty_flutter/theme/app_theme.dart';
import 'package:casinoloyalty_flutter/services/notification_service.dart';
import 'package:casinoloyalty_flutter/services/real_notification_service.dart';
import 'package:casinoloyalty_flutter/services/background_service_impl.dart';
import 'package:casinoloyalty_flutter/services/messaging_service.dart'; // Import MessagingService

// Nuevos imports para mejoras
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:casinoloyalty_flutter/core/services/analytics_service.dart';
import 'package:casinoloyalty_flutter/core/services/crashlytics_service.dart';

// import 'package:casinoloyalty_flutter/services/firebase_service.dart'; // Comentado para trabajar con datos mock

void main() async {
  // Capturar errores de la zona
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

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

    // Inicializaciones paralelas para mejorar tiempo de inicio
    await Future.wait([
      initializeDateFormatting('es_ES', null),
      _initializeTimezone(),
      _initializeFirebaseServices(),
    ]);

    // Inicializaciones secuenciales (dependen de las anteriores)
    await NotificationService.initialize();
    AppLogger.info('✅ NotificationService inicializado');

    // Initialize Firebase Messaging
    await MessagingService.initialize();
    AppLogger.info('✅ MessagingService inicializado');

    NotificationService.onNotificationTap = (payload) {
      if (payload == null || payload.isEmpty) {
        rootNavigatorKey.currentContext?.go('/home');
        return;
      }

      // Allow using route payloads directly.
      if (payload.startsWith('/')) {
        rootNavigatorKey.currentContext?.go(payload);
        return;
      }

      // Default fallback.
      rootNavigatorKey.currentContext?.go('/home');
    };

    await BackgroundServiceImpl.initialize();
    AppLogger.info('✅ BackgroundService inicializado');

    AppLogger.info('✅ Todas las inicializaciones completadas');

    runApp(const ProviderScope(child: DreamsLoyaltyApp()));
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

/// Inicializa servicios de Firebase (Analytics, Crashlytics).
Future<void> _initializeFirebaseServices() async {
  try {
    // Inicializar Firebase (necesario para Firestore en todas las plataformas)
    await FirebaseService.initialize();
    AppLogger.info('✅ Firebase core inicializado');

    // Initialize App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      webProvider: ReCaptchaEnterpriseProvider(
          'recaptcha-site-key'), // Configure if needed
    );
    AppLogger.info('✅ Firebase App Check inicializado');

    // Firebase Crashlytics y Analytics no están soportados en Web de la misma forma
    // Solo inicializar estas herramientas de monitoreo en plataformas móviles por ahora
    if (!kIsWeb) {
      // Inicializar Crashlytics primero para capturar errores de Analytics
      await CrashlyticsService.initialize();
      AppLogger.info('✅ Crashlytics inicializado');

      // Inicializar Analytics
      await AnalyticsService.initialize();
      AppLogger.info('✅ Analytics inicializado');
    } else {
      AppLogger.info('ℹ️ Analytics y Crashlytics omitidos en Web');
    }
  } catch (e, stack) {
    AppLogger.error('Error inicializando Firebase services', e, stack);
    // Continuar sin Firebase - la app funcionará con datos mock si están implementados
  }
}

/// Widget principal de la aplicación.
class DreamsLoyaltyApp extends ConsumerWidget {
  const DreamsLoyaltyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Inicializar notificaciones reales
    ref.watch(realNotificationServiceProvider);

    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Dreams Club',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
      // Observer de Analytics para tracking automático de navegación
      // navigatorObservers: [
      //   if (AnalyticsService.observer != null) AnalyticsService.observer!,
      // ],
      builder: (context, child) {
        // Wrapper para manejo de errores en UI
        return _ErrorBoundary(child: child ?? const SizedBox.shrink());
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
