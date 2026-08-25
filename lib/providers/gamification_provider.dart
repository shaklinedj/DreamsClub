import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/gamification_model.dart';
import 'package:casinoloyalty_flutter/models/user_model.dart'; // Import this!
import 'package:casinoloyalty_flutter/services/gamification_service.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

// ============================================================================
// LOGROS - Enfocados 100% en DREAMS COYHAIQUE, RACHAS Y RECOMPENSAS DIGITALES
// ============================================================================
const List<Achievement> _defaultAchievements = [
  // Rachas Diarias
  Achievement(
    id: 'first_coyhaique_streak',
    title: 'Bienvenido a Coyhaique',
    description: 'Entra a la app y activa tu primera racha',
    icon: '🏔️',
    pointsReward: 100,
    targetValue: 1,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Pack Stickers Oficiales Coyhaique',
  ),
  Achievement(
    id: 'streak_3_days',
    title: 'Racha Austral (3 Días)',
    description: 'Mantén 3 días seguidos de racha en la app',
    icon: '🔥',
    pointsReward: 300,
    targetValue: 3,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Pack Stickers Animados + Tema Dorado VIP',
  ),
  Achievement(
    id: 'streak_7_days',
    title: 'Leyenda Patagónica (7 Días)',
    description: 'Completa una semana entera de racha diaria',
    icon: '🏆',
    pointsReward: 700,
    targetValue: 7,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Pack Stickers VIP Gold + Tema Platino Austral',
  ),
  Achievement(
    id: 'streak_14_days',
    title: 'Maestro de Coyhaique',
    description: 'Alcanza 14 días seguidos en Dreams Club',
    icon: '👑',
    pointsReward: 1500,
    targetValue: 14,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Tema Patagónico Exclusivo para la App',
  ),
  Achievement(
    id: 'streak_30_days',
    title: 'Leyenda Absoluta (30 Días)',
    description: 'Alcanza 30 días seguidos de racha en Dreams Club',
    icon: '🎰',
    pointsReward: 3000,
    targetValue: 30,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Tema Diamante Oscuro + Pack Leyenda',
  ),

  // Minijuegos y Entretenimiento
  Achievement(
    id: 'play_roulette',
    title: 'Giro Afortunado',
    description: 'Juega una ronda en la Ruleta de la Suerte',
    icon: '🎰',
    pointsReward: 200,
    targetValue: 1,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.special,
    rewardDescription: 'Sticker Ruleta de la Fortuna',
  ),
  Achievement(
    id: 'play_mania',
    title: 'Fiebre Dreams Manía',
    description: 'Participa en el minijuego Dreams Manía',
    icon: '⭐',
    pointsReward: 300,
    targetValue: 1,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.special,
    rewardDescription: 'Sticker Estrella Dreams',
  ),
  Achievement(
    id: 'share_streak',
    title: 'Embajador Dreams',
    description: 'Comparte tu racha diaria con un amigo',
    icon: '📱',
    pointsReward: 250,
    targetValue: 1,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.special,
    rewardDescription: 'Sticker Corona VIP WhatsApp',
  ),
];

class AchievementsNotifier extends StateNotifier<List<Achievement>> {
  AchievementsNotifier(this.ref) : super(_defaultAchievements) {
    _loadAchievements();
    _listenToUserUpdates();
  }

  final Ref ref;
  final GamificationService _service = GamificationService();

  void _listenToUserUpdates() {
    ref.listen<User>(userProvider, (previous, next) {
      if (previous == null || previous.streak != next.streak) {
        _checkStreakAchievements(next.streak);
      }
    });
  }

  Future<void> _checkStreakAchievements(int streak) async {
    if (state.any((a) => a.id == 'first_coyhaique_streak')) {
      await updateProgress('first_coyhaique_streak', streak);
    }
    if (state.any((a) => a.id == 'streak_3_days')) {
      await updateProgress('streak_3_days', streak);
    }
    if (state.any((a) => a.id == 'streak_7_days')) {
      await updateProgress('streak_7_days', streak);
    }
    if (state.any((a) => a.id == 'streak_14_days')) {
      await updateProgress('streak_14_days', streak);
    }
    if (state.any((a) => a.id == 'streak_30_days')) {
      await updateProgress('streak_30_days', streak);
    }
    if (streak >= 1) {
      if (state.any((a) => a.id == 'play_roulette')) {
        await updateProgress('play_roulette', 1);
      }
      if (state.any((a) => a.id == 'play_mania')) {
        await updateProgress('play_mania', 1);
      }
      if (state.any((a) => a.id == 'share_streak')) {
        await updateProgress('share_streak', 1);
      }
    }
  }

  Future<void> _loadAchievements() async {
    final List<Achievement> loadedAchievements = [];

    for (final achievement in _defaultAchievements) {
      final data = await _service.getAchievementData(achievement.id);
      loadedAchievements.add(
        achievement.copyWith(
          isUnlocked: data['isUnlocked'] ?? false,
          currentValue: data['currentValue'] ?? 0,
          progress: data['progress'] ?? 0.0,
          unlockedAt: data['unlockedAt'] != null
              ? DateTime.parse(data['unlockedAt'])
              : null,
        ),
      );
    }

    state = loadedAchievements;
  }

  Future<void> unlockAchievement(String id) async {
    final achievement = state.firstWhere((a) => a.id == id);

    if (!achievement.isUnlocked) {
      await _service.unlockAchievement(id, achievement.pointsReward);

      state = [
        for (final a in state)
          if (a.id == id)
            a.copyWith(
              isUnlocked: true,
              unlockedAt: DateTime.now(),
              progress: 1.0,
              currentValue: a.targetValue,
            )
          else
            a
      ];
    }
  }

  Future<void> updateProgress(String id, int newValue) async {
    final achievement = state.firstWhere((a) => a.id == id);
    await _service.updateAchievementProgress(
        id, newValue, achievement.targetValue);

    final isNowUnlocked = newValue >= achievement.targetValue;
    final shouldUnlock = isNowUnlocked && !achievement.isUnlocked;

    if (shouldUnlock) {
      await _service.addPoints(achievement.pointsReward);
      // Disparar confeti y popup
      ref.read(confettiTriggerProvider.notifier).state = achievement;
    }

    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(
            currentValue: newValue,
            progress: (newValue / a.targetValue).clamp(0.0, 1.0),
            isUnlocked: isNowUnlocked,
            unlockedAt: shouldUnlock
                ? DateTime.now()
                : (isNowUnlocked ? a.unlockedAt : null),
          )
        else
          a
    ];
  }

  // Registrar una visita a casino (requiere mínimo 24 horas desde la última)
  // Retorna true si la visita fue válida y contó, false si fue rechazada
  Future<bool> registerCasinoVisit(String casinoId) async {
    // Verificar si la visita es válida (24 horas mínimo)
    final isValidVisit = await _service.incrementTotalVisitsIfValid();

    if (!isValidVisit) {
      // La visita no es válida (ya visitó hoy), no actualizar logros
      return false;
    }

    final totalVisits = await _service.getTotalVisits();
    ref.read(userProvider.notifier).setTotalVisits(totalVisits);

    // Agregar casino a la lista de visitados (esto sí se hace siempre para tracking)
    await _service.addVisitedCasino(casinoId);

    // Actualizar racha
    final streak = await _service.updateStreak();
    // Esto actualizará Firebase y disparará los listeners locales
    await ref.read(userProvider.notifier).setStreak(streak);

    // Si la nueva racha es un hito de celebración, disparar trigger activo
    if ([1, 3, 7, 14, 30].contains(streak)) {
      ref.read(streakCelebrationTriggerProvider.notifier).state = streak;
    }

    return true;
  }

  int get totalUnlocked => state.where((a) => a.isUnlocked).length;
  int get totalPoints => state
      .where((a) => a.isUnlocked)
      .fold(0, (sum, a) => sum + a.pointsReward);
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, List<Achievement>>((ref) {
  return AchievementsNotifier(ref);
});

// Provider para disparar el evento de confeti
final confettiTriggerProvider = StateProvider<Achievement?>((ref) => null);

// Provider para disparar celebraciones de racha únicamente tras registro físico
final streakCelebrationTriggerProvider = StateProvider<int?>((ref) => null);

// ============================================================================
// MISIONES DIARIAS - Solo relacionadas con VISITAS
// ============================================================================
List<DailyMission> _generateDailyMissions() {
  return [
    const DailyMission(
      id: 'visit_casino_today',
      title: 'Visita Dreams Coyhaique',
      description: 'Visita el casino hoy y registra tu visita',
      icon: '🏛️',
      pointsReward: 100,
      targetValue: 1,
      currentValue: 0,
      progress: 0.0,
      type: MissionType.visit,
      rewardDescription: 'Stickers de Bienvenida 🏔️',
    ),
    const DailyMission(
      id: 'streak_3_days_mission',
      title: 'Constancia Patagónica',
      description: 'Alcanza una racha de 3 días seguidos',
      icon: '🔥',
      pointsReward: 200,
      targetValue: 3,
      currentValue: 0,
      progress: 0.0,
      type: MissionType.visit,
      rewardDescription: 'Tema Dorado VIP 👑',
    ),
    const DailyMission(
      id: 'maintain_streak',
      title: 'Mantén tu Racha',
      description: 'No pierda tu racha diaria en Coyhaique',
      icon: '⚡',
      pointsReward: 50,
      targetValue: 1,
      currentValue: 0,
      progress: 0.0,
      type: MissionType.visit,
      rewardDescription: 'Stickers de Personalización 🎨',
    ),
  ];
}

class DailyMissionsNotifier extends StateNotifier<List<DailyMission>> {
  DailyMissionsNotifier(this.ref) : super(_generateDailyMissions()) {
    _loadMissions();
    _listenToUserUpdates();
  }

  final Ref ref;
  final GamificationService _service = GamificationService();

  void _listenToUserUpdates() {
    ref.listen<User>(userProvider, (previous, next) {
      if (previous == null) return;

      // Check for visit today
      if (next.totalVisits > previous.totalVisits) {
        completeMission('visit_casino_today');
      }

      // Check for 3-day streak mission
      if (next.streak >= 3) {
        completeMission('streak_3_days_mission');
      }

      // Check for streak maintenance
      if (next.streak > 0 && next.streak >= previous.streak) {
        completeMission('maintain_streak');
      }
    });
  }

  Future<void> _loadMissions() async {
    final List<DailyMission> loadedMissions = [];

    for (final mission in state) {
      final data = await _service.getMissionData(mission.id);
      loadedMissions.add(
        mission.copyWith(
          isCompleted: data['isCompleted'] ?? false,
          currentValue: data['currentValue'] ?? 0,
          progress: data['progress'] ?? 0.0,
        ),
      );
    }

    state = loadedMissions;
  }

  Future<void> completeMission(String id) async {
    final mission =
        state.firstWhere((m) => m.id == id, orElse: () => state.first);
    final wasCompleted = mission.isCompleted;

    // Guardar en servicio
    await _service.updateMissionProgress(
        id, mission.targetValue, mission.targetValue);

    state = [
      for (final m in state)
        if (m.id == id)
          m.copyWith(
            isCompleted: true,
            progress: 1.0,
            currentValue: m.targetValue,
          )
        else
          m
    ];

    // Agregar puntos solo si no estaba completada antes
    if (!wasCompleted) {
      ref.read(userProvider.notifier).addPoints(mission.pointsReward);
    }
  }

  Future<void> updateProgress(String id, int newValue) async {
    final mission =
        state.firstWhere((m) => m.id == id, orElse: () => state.first);
    final wasCompleted = mission.isCompleted;
    final willBeCompleted = newValue >= mission.targetValue;

    // Guardar en servicio
    await _service.updateMissionProgress(id, newValue, mission.targetValue);

    state = [
      for (final m in state)
        if (m.id == id)
          m.copyWith(
            currentValue: newValue,
            progress: (newValue / m.targetValue).clamp(0.0, 1.0),
            isCompleted: willBeCompleted,
          )
        else
          m
    ];

    // Agregar puntos si se completó ahora
    if (!wasCompleted && willBeCompleted) {
      ref.read(userProvider.notifier).addPoints(mission.pointsReward);
    }
  }

  int get completedCount => state.where((m) => m.isCompleted).length;
  int get totalPointsEarned => state
      .where((m) => m.isCompleted)
      .fold(0, (sum, m) => sum + m.pointsReward);
}

final dailyMissionsProvider =
    StateNotifierProvider<DailyMissionsNotifier, List<DailyMission>>((ref) {
  return DailyMissionsNotifier(ref);
});

// ============================================================================
// RACHA DE VISITAS
// ============================================================================
class StreakNotifier extends StateNotifier<StreakData> {
  final Ref ref;
  final GamificationService _service = GamificationService();

  StreakNotifier(this.ref) : super(const StreakData()) {
    _loadStreak();
    _listenToUserUpdates();
  }

  void _listenToUserUpdates() {
    ref.listen<User>(userProvider, (previous, next) {
      if (previous == null || previous.streak != next.streak) {
        _syncWithFirebase(next.streak);
      }
    });
  }

  Future<void> _syncWithFirebase(int firebaseStreak) async {
    final lastVisit = await _service.getLastVisitDate();
    final weekProgress = await _service.getCurrentWeekProgress();
    final cloudLongestStreak = await _service.getLongestStreak();

    final longestStreak = cloudLongestStreak > firebaseStreak
        ? cloudLongestStreak
        : firebaseStreak;

    state = state.copyWith(
      currentStreak: firebaseStreak,
      longestStreak: longestStreak > state.longestStreak
          ? longestStreak
          : state.longestStreak,
      lastCheckIn: lastVisit,
      weekProgress: weekProgress,
      bonusMultiplier: _calculateMultiplier(firebaseStreak),
    );
  }

  Future<void> _loadStreak() async {
    final firebaseStreak = ref.read(userProvider).streak;
    await _syncWithFirebase(firebaseStreak);
  }

  Future<void> registerVisit() async {
    // Ya no hacemos incremento doble aquí. Se hace desde AchievementsNotifier.
    // Solo forzamos resincronización por si acaso.
    final firebaseStreak = ref.read(userProvider).streak;
    await _syncWithFirebase(firebaseStreak);
  }

  int _calculateMultiplier(int streak) {
    if (streak >= 30) return 5;
    if (streak >= 14) return 3;
    if (streak >= 7) return 2;
    return 1;
  }

  String getStreakReward() {
    if (state.currentStreak >= 14) return '🌲 Tema Especial Patagónico';
    if (state.currentStreak >= 7) {
      return '❄️ Tema Platino Austral & Stickers VIP';
    }
    if (state.currentStreak >= 3) return '👑 Tema Dorado VIP & Stickers Memes';
    if (state.currentStreak >= 1) return '🏔️ Pack de Stickers Patagónicos';
    return '🔥 ¡Inicia tu racha hoy!';
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakData>((ref) {
  return StreakNotifier(ref);
});
