import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/game_config_model.dart';
import 'package:casinoloyalty_flutter/providers/location_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_history_provider.dart';

// --- State ---
enum GameStatus {
  available,
  lockedLocation, // Not in casino
  lockedTime, // Wrong day/time
  lockedFrequency, // Already played today
  lockedMembership, // User level not allowed
  maintenance, // isActive = false
  loading, // Checking history/location
}

class GameAvailability {
  final GameConfig config;
  final GameStatus status;
  final String? message; // Reason for lock

  GameAvailability({required this.config, required this.status, this.message});
}

// --- Repository (Real Firestore) ---
class GameConfigRepository {
  Stream<List<GameConfig>> watchConfigs() {
    return FirebaseFirestore.instance
        .collection('game_configs')
        .snapshots()
        .map((snapshot) {
      final existingIds = snapshot.docs.map((d) => d.id).toSet();
      final defaults = _getDefaults();

      // Check if any default game is missing
      bool anyMissing = false;
      for (final def in defaults) {
        if (!existingIds.contains(def.gameId)) {
          anyMissing = true;
          break;
        }
      }

      if (anyMissing) {
        _ensureDefaultConfigs(existingIds);
      }

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs
          .map((doc) => GameConfig.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  List<GameConfig> _getDefaults() {
    return [
      const GameConfig(
        gameId: 'dreams_mania',
        title: 'Dreams Manía',
        isActive: true,
        requiresLocation: true,
        frequency: GameFrequency.daily,
      ),
      const GameConfig(
        gameId: 'roulette',
        title: 'Ruleta de la Suerte',
        isActive: true,
        requiresLocation: true,
        frequency: GameFrequency.daily,
      ),
      const GameConfig(
        gameId: 'slots',
        title: 'Máquina de Premios',
        isActive: true,
        requiresLocation: true,
        frequency: GameFrequency.daily,
      ),
      const GameConfig(
        gameId: 'dreams_match',
        title: 'Dreams Match',
        isActive: true,
        requiresLocation: true,
        frequency: GameFrequency.unlimited,
      ),
    ];
  }

  // Ensure missing defaults are created
  Future<void> _ensureDefaultConfigs(Set<String> existingIds) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    final defaults = _getDefaults();
    bool needsCommit = false;

    for (final config in defaults) {
      if (!existingIds.contains(config.gameId)) {
        final docRef = db.collection('game_configs').doc(config.gameId);
        batch.set(docRef, config.toMap());
        needsCommit = true;
      }
    }

    if (needsCommit) {
      await batch.commit();
    }
  }
}

// --- Provider ---
final gameConfigsProvider = StreamProvider<List<GameConfig>>((ref) {
  final repo = GameConfigRepository();
  return repo.watchConfigs();
});

// Logic Provider to check status
final gameAvailabilityProvider =
    Provider.family<GameAvailability, String>((ref, gameId) {
  final configsAsync = ref.watch(gameConfigsProvider);
  final locationState = ref.watch(locationProvider);
  final user = ref.watch(userProvider); // Get current user
  final historyAsync = ref.watch(gameHistoryProvider);

  // Default fallback if loading or error
  final defaultConfig = GameConfig(
      gameId: gameId, title: 'Juego', isActive: false, requiresLocation: true);

  // If history is still loading, we might want to wait or show loading,
  // but to avoid blocking UI with spinners for cards, we proceed with available info
  // and re-evaluate when loaded. Defaulting to available if not loaded might be risky,
  // locking is safer.
  if (historyAsync.isLoading) {
    return GameAvailability(
        config: defaultConfig,
        status: GameStatus.loading,
        message: 'Cargando...');
  }

  return configsAsync.when(
    data: (configs) {
      final config = configs.firstWhere((c) => c.gameId == gameId,
          orElse: () => defaultConfig);

      // 1. Is Active?
      if (!config.isActive) {
        return GameAvailability(
            config: config,
            status: GameStatus.maintenance,
            message: 'Juego en mantenimiento');
      }

      // 2. Location Check
      if (config.requiresLocation && !locationState.isNearAnyCasino) {
        return GameAvailability(
            config: config,
            status: GameStatus.lockedLocation,
            message: locationState.isLoading
                ? 'Verificando ubicación...'
                : 'Debes estar en un Casino Dreams');
      }

      // 3. Time/Day Check
      final now = DateTime.now();
      if (config.activeWeekdays.isNotEmpty &&
          !config.activeWeekdays.contains(now.weekday)) {
        return GameAvailability(
            config: config,
            status: GameStatus.lockedTime,
            message: 'Solo disponible días específicos');
      }

      if (config.validFrom != null && now.isBefore(config.validFrom!)) {
        return GameAvailability(
            config: config,
            status: GameStatus.lockedTime,
            message: 'Próximamente');
      }

      // 4. User Level (Membership) Check
      if (config.allowedUserLevels.isNotEmpty) {
        final userLevelName =
            user.level.name; // 'black', 'gold', 'platinum', 'blue'
        if (!config.allowedUserLevels.contains(userLevelName)) {
          return GameAvailability(
              config: config,
              status: GameStatus.lockedMembership,
              message:
                  'Exclusivo para miembros ${_formatAllowedLevels(config.allowedUserLevels)}');
        }
      }

      // 5. Frequency Check
      if (config.frequency != GameFrequency.unlimited) {
        final history = historyAsync.asData?.value;
        if (history != null) {
          final lastPlayed = history[gameId];
          if (lastPlayed != null) {
            final diff = now.difference(lastPlayed);

            if (config.frequency == GameFrequency.daily ||
                config.frequency == GameFrequency.oncePerStay) {
              // 'oncePerStay' treated as 24h cooldown for now given MVP context
              if (diff.inHours < 24) {
                final hoursLeft = 24 - diff.inHours;
                return GameAvailability(
                  config: config,
                  status: GameStatus.lockedFrequency,
                  message: 'Disponible en $hoursLeft hrs',
                );
              }
            } else if (config.frequency == GameFrequency.weekly) {
              if (diff.inDays < 7) {
                final daysLeft = 7 - diff.inDays;
                return GameAvailability(
                  config: config,
                  status: GameStatus.lockedFrequency,
                  message: 'Disponible en $daysLeft días',
                );
              }
            }
          }
        }
      }

      return GameAvailability(config: config, status: GameStatus.available);
    },
    error: (_, __) => GameAvailability(
        config: defaultConfig,
        status: GameStatus.maintenance,
        message: 'Error de conexión'),
    loading: () => GameAvailability(
        config: defaultConfig,
        status: GameStatus.loading,
        message: 'Cargando...'),
  );
});

// Helper to format allowed levels for display
String _formatAllowedLevels(List<String> levels) {
  if (levels.isEmpty) return '';
  final formatted = levels.map((l) {
    switch (l) {
      case 'black':
        return 'Black';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      case 'blue':
        return 'Blue';
      default:
        return l;
    }
  }).toList();
  if (formatted.length == 1) return formatted.first;
  return '${formatted.sublist(0, formatted.length - 1).join(', ')} o ${formatted.last}';
}
