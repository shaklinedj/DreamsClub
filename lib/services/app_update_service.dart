import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ota_update/ota_update.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Servicio unificado para la gestión de actualizaciones in-app y parches OTA.
class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  /// Ejecuta la descarga en segundo plano del APK e instala automáticamente en Android.
  /// Retorna un Stream con los eventos de progreso [OtaEvent] (0% a 100%).
  Stream<OtaEvent> downloadAndInstallApk(String apkUrl) {
    AppLogger.info('Iniciando descarga in-app del APK desde: $apkUrl');
    
    try {
      return OtaUpdate().execute(
        apkUrl,
        destinationFilename: 'DreamsApp_update.apk',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error al iniciar OtaUpdate stream', e, stackTrace);
      return Stream.error(e);
    }
  }

  /// Verifica si el sistema operativo soporta actualización in-app de APK nativo.
  bool get isInAppApkSupported {
    return defaultTargetPlatform == TargetPlatform.android && !kIsWeb;
  }
}
