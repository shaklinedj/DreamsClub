/// Servicio de conectividad para monitorear estado de red.
///
/// Proporciona información en tiempo real sobre la conectividad
/// y permite manejar modo offline gracefully.
library;

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Estado de conectividad actual.
enum ConnectivityState {
  online,
  offline,
  unknown,
}

/// Notifier para el estado de conectividad.
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  ConnectivityNotifier() : super(ConnectivityState.unknown) {
    _initialize();
  }

  StreamSubscription? _subscription;
  final Connectivity _connectivity = Connectivity();

  Future<void> _initialize() async {
    // Obtener estado inicial
    final results = await _connectivity.checkConnectivity();
    _updateState(results);

    // Escuchar cambios
    _subscription = _connectivity.onConnectivityChanged.listen(_updateState);
  }

  void _updateState(List<ConnectivityResult> results) {
    final hasConnection =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    final newState =
        hasConnection ? ConnectivityState.online : ConnectivityState.offline;

    if (state != newState) {
      AppLogger.info('Conectividad cambió: ${state.name} → ${newState.name}');
      state = newState;
    }
  }

  /// Verifica manualmente el estado de conexión.
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _updateState(results);
    return state == ConnectivityState.online;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider para el estado de conectividad.
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

/// Provider convenience para verificar si está online.
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity == ConnectivityState.online;
});

/// Provider convenience para verificar si está offline.
final isOfflineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity == ConnectivityState.offline;
});
