import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

// IMPORTANT: Background service is disabled in Spark / No-GPS mode.
@pragma('vm:entry-point')
void backgroundServiceOnStart(ServiceInstance service) {}

@pragma('vm:entry-point')
Future<bool> backgroundServiceOnIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
class BackgroundServiceImpl {
  @pragma('vm:entry-point')
  static Future<void> initialize() async {
    debugPrint('Background Service DISABLED (Spark Plan / No-GPS Mode)');
  }
}

