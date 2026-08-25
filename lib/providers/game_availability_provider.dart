import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/game_config_model.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_history_provider.dart';
import 'package:casinoloyalty_flutter/services/prize_service.dart';

// --- State ---
enum GameStatus {
  available,
  lockedLocation,
  lockedTime, // Horario o día no permitido
  lockedFrequency, // Cooldown de 48h (o configurado)
  lockedStreak, // Requiere mayor racha
  maintenance, // isActive = false
  loading,
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
        requiresLocation: false,
        frequency: GameFrequency.daily,
      ),
      const GameConfig(
        gameId: 'roulette',
        title: 'Ruleta de la Suerte',
        isActive: true,
        requiresLocation: false,
        frequency: GameFrequency.daily,
      ),
      const GameConfig(
        gameId: 'slots',
        title: 'Máquina de Premios',
        isActive: true,
        requiresLocation: false,
        frequency: GameFrequency.daily,
      ),
      const GameConfig(
        gameId: 'dreams_match',
        title: 'Dreams Match',
        isActive: true,
        requiresLocation: false,
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

// Global game configs stream provider
final gameConfigsProvider = StreamProvider<List<GameConfig>>((ref) {
  final repo = GameConfigRepository();
  return repo.watchConfigs();
});

// Global rules config stream provider from Firestore
final globalGameRulesProvider = StreamProvider<GameRulesConfig>((ref) {
  return PrizeService().streamRulesConfig();
});

final gameAvailabilityClockProvider =
    StreamProvider.autoDispose<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

// Logic Provider to check status across ALL mini-games
final gameAvailabilityProvider =
    Provider.family<GameAvailability, String>((ref, gameId) {
  final configsAsync = ref.watch(gameConfigsProvider);
  final rulesAsync = ref.watch(globalGameRulesProvider);
  final user = ref.watch(userProvider);
  final historyAsync = ref.watch(gameHistoryProvider);
  ref.watch(gameAvailabilityClockProvider);

  final defaultConfig = GameConfig(
    gameId: gameId,
    title: 'Juego',
    isActive: false,
    requiresLocation: false,
  );

  if (historyAsync.isLoading || rulesAsync.isLoading) {
    return GameAvailability(
      config: defaultConfig,
      status: GameStatus.loading,
      message: 'Cargando reglas...',
    );
  }

  final rules = rulesAsync.value ?? const GameRulesConfig();

  return configsAsync.when(
    data: (configs) {
      final config = configs.firstWhere(
        (c) => c.gameId == gameId,
        orElse: () => defaultConfig,
      );

      // 1. Is Active?
      if (!config.isActive) {
        return GameAvailability(
          config: config,
          status: GameStatus.maintenance,
          message: 'Juego en mantenimiento',
        );
      }

      final now = DateTime.now();

      // 2. Allowed Days of the Week Check (0=Sun, 1=Mon, ..., 6=Sat)
      // Note: DateTime.weekday is 1 (Mon) to 7 (Sun). Convert 7 -> 0 for Sunday
      final currentWeekday = now.weekday % 7;
      if (rules.allowedDays.isNotEmpty &&
          !rules.allowedDays.contains(currentWeekday)) {
        return GameAvailability(
          config: config,
          status: GameStatus.lockedTime,
          message: 'No disponible hoy según calendario',
        );
      }

      // 3. Time Window Check (e.g. 18:00 to 02:00)
      if (rules.timeWindowEnabled) {
        final currentHour = now.hour;
        bool isInsideWindow;
        if (rules.startHour <= rules.endHour) {
          isInsideWindow =
              currentHour >= rules.startHour && currentHour < rules.endHour;
        } else {
          // Crosses midnight (e.g. 18 to 2)
          isInsideWindow =
              currentHour >= rules.startHour || currentHour < rules.endHour;
        }

        if (!isInsideWindow) {
          final startFormatted = rules.startHour.toString().padLeft(2, '0');
          final endFormatted = rules.endHour.toString().padLeft(2, '0');
          return GameAvailability(
            config: config,
            status: GameStatus.lockedTime,
            message: 'Disponible de $startFormatted:00 a $endFormatted:00 hrs',
          );
        }
      }

      // 4. User Streak Tier Check (Streak in days)
      if (rules.minStreakRequired > 0 &&
          user.streak < rules.minStreakRequired) {
        return GameAvailability(
          config: config,
          status: GameStatus.lockedStreak,
          message:
              'Requiere racha mínima de ${rules.minStreakRequired} días (Tienes ${user.streak}d)',
        );
      }

      final history = historyAsync.asData?.value;
      if (history != null && history.isNotEmpty) {
        final lastPlayed = history[gameId];
        final intervalStart =
            now.subtract(Duration(hours: rules.cooldownHours));
        final playsInInterval = history.values
            .where((playedAt) => playedAt.isAfter(intervalStart))
            .toList();

        if (rules.cooldownHours > 0 && lastPlayed != null) {
          final cooldownEnd =
              lastPlayed.add(Duration(hours: rules.cooldownHours));
          final remaining = cooldownEnd.difference(now);
          if (remaining > Duration.zero) {
            final hoursLeft = remaining.inHours;
            final minutesLeft = remaining.inMinutes % 60;
            final secondsLeft = remaining.inSeconds % 60;
            final String timeMsg = hoursLeft > 0
                ? '${hoursLeft}h ${minutesLeft}min'
                : minutesLeft > 0
                    ? '${minutesLeft}min ${secondsLeft}s'
                    : '${secondsLeft}s';
            return GameAvailability(
              config: config,
              status: GameStatus.lockedFrequency,
              message: 'Ya jugaste este juego. Espera $timeMsg',
            );
          }
        }

        if (rules.cooldownHours > 0 &&
            rules.maxGamesPerInterval > 0 &&
            playsInInterval.length >= rules.maxGamesPerInterval) {
          final earliestPlay = playsInInterval.reduce(
            (earliest, playedAt) =>
                playedAt.isBefore(earliest) ? playedAt : earliest,
          );
          final remaining = earliestPlay
              .add(Duration(hours: rules.cooldownHours))
              .difference(now);
          final minutesLeft = remaining.inMinutes.ceil();
          return GameAvailability(
            config: config,
            status: GameStatus.lockedFrequency,
            message: 'Alcanzaste el límite. Podrás jugar en $minutesLeft min',
          );
        }
      }

      return GameAvailability(config: config, status: GameStatus.available);
    },
    error: (_, __) => GameAvailability(
      config: defaultConfig,
      status: GameStatus.maintenance,
      message: 'Error de conexión',
    ),
    loading: () => GameAvailability(
      config: defaultConfig,
      status: GameStatus.loading,
      message: 'Cargando...',
    ),
  );
});
