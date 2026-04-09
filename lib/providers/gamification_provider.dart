import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/gamification_model.dart';
import 'package:casinoloyalty_flutter/models/user_model.dart'; // Import this!
import 'package:casinoloyalty_flutter/services/gamification_service.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

// ============================================================================
// LOGROS - Enfocados solo en VISITAS A CASINOS
// ============================================================================
const List<Achievement> _defaultAchievements = [
  // Primera visita
  Achievement(
    id: 'first_casino_visit',
    title: 'Bienvenido a Dreams',
    description: 'Visita tu primer casino Dreams',
    icon: '🎉',
    pointsReward: 100,
    targetValue: 1,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: '1 Bebida de cortesía',
  ),

  // Visitas múltiples en días diferentes
  Achievement(
    id: 'visit_3_days',
    title: 'Visitante Frecuente',
    description: 'Visita un casino 3 días seguidos',
    icon: '🔥',
    pointsReward: 300,
    targetValue: 3,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: '1 Espumante',
  ),
  Achievement(
    id: 'visit_7_days',
    title: 'Guerrero Semanal',
    description: 'Visita un casino 7 días seguidos',
    icon: '🏆',
    pointsReward: 700,
    targetValue: 7,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Cena para 2 en Restaurante Dreams',
  ),
  Achievement(
    id: 'visit_30_days',
    title: 'Leyenda Mensual',
    description: 'Mantén una racha de 30 días visitando casinos',
    icon: '👑',
    pointsReward: 3000,
    targetValue: 30,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Noche gratis en Hotel Dreams',
  ),

  // Múltiples casinos
  Achievement(
    id: 'visit_2_casinos',
    title: 'Explorador',
    description: 'Visita 2 casinos Dreams diferentes',
    icon: '🗺️',
    pointsReward: 500,
    targetValue: 2,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.exploration,
    rewardDescription: '5,000 Puntos Dreams',
  ),
  Achievement(
    id: 'visit_all_casinos',
    title: 'Coleccionista Dreams',
    description: 'Visita todos los casinos Dreams de Chile',
    icon: '🌟',
    pointsReward: 5000,
    targetValue: 5,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.exploration,
    rewardDescription: 'Upgrade VIP por 1 mes',
  ),

  // Visitas totales acumuladas
  Achievement(
    id: 'total_10_visits',
    title: 'Habitué',
    description: 'Realiza 10 visitas a cualquier casino',
    icon: '⭐',
    pointsReward: 200,
    targetValue: 10,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: '2,000 Puntos Dreams',
  ),
  Achievement(
    id: 'total_50_visits',
    title: 'VIP Dreams',
    description: 'Realiza 50 visitas a cualquier casino',
    icon: '💎',
    pointsReward: 1000,
    targetValue: 50,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Entrada VIP permanente',
  ),
  Achievement(
    id: 'total_100_visits',
    title: 'Leyenda Dreams',
    description: 'Realiza 100 visitas a cualquier casino',
    icon: '🏅',
    pointsReward: 5000,
    targetValue: 100,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.visits,
    rewardDescription: 'Weekend VIP con acompañante',
  ),

  // Especiales
  Achievement(
    id: 'weekend_warrior',
    title: 'Rey del Fin de Semana',
    description: 'Visita un casino todos los fines de semana del mes',
    icon: '🎊',
    pointsReward: 800,
    targetValue: 4,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.special,
    rewardDescription: 'Botella de Champagne',
  ),
  Achievement(
    id: 'night_owl',
    title: 'Búho Nocturno',
    description: 'Visita un casino después de las 22:00 hrs, 5 veces',
    icon: '🦉',
    pointsReward: 400,
    targetValue: 5,
    currentValue: 0,
    progress: 0.0,
    category: AchievementCategory.special,
    rewardDescription: 'Cocktail especial',
  ),
];

class AchievementsNotifier extends StateNotifier<List<Achievement>> {
  AchievementsNotifier(this.ref) : super(_defaultAchievements) {
    _loadAchievements();
  }

  final Ref ref;
  final GamificationService _service = GamificationService();

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

    final shouldUnlock =
        newValue >= achievement.targetValue && !achievement.isUnlocked;

    if (shouldUnlock) {
      await _service.addPoints(achievement.pointsReward);
    }

    state = [
      for (final a in state)
        if (a.id == id)
          a.copyWith(
            currentValue: newValue,
            progress: (newValue / a.targetValue).clamp(0.0, 1.0),
            isUnlocked: newValue >= a.targetValue,
            unlockedAt: shouldUnlock ? DateTime.now() : a.unlockedAt,
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

    // Agregar casino a la lista de visitados (esto sí se hace siempre para tracking)
    await _service.addVisitedCasino(casinoId);
    final visitedCasinos = await _service.getVisitedCasinos();

    // Actualizar racha
    final streak = await _service.updateStreak();

    // Actualizar logros de visitas totales
    await updateProgress('total_10_visits', totalVisits);
    await updateProgress('total_50_visits', totalVisits);
    await updateProgress('total_100_visits', totalVisits);

    // Actualizar logros de casinos diferentes
    await updateProgress('visit_2_casinos', visitedCasinos.length);
    await updateProgress('visit_all_casinos', visitedCasinos.length);

    // Actualizar logros de racha
    await updateProgress('visit_3_days', streak);
    await updateProgress('visit_7_days', streak);
    await updateProgress('visit_30_days', streak);

    // Primera visita
    final firstVisit = state.firstWhere((a) => a.id == 'first_casino_visit');
    if (!firstVisit.isUnlocked) {
      await unlockAchievement('first_casino_visit');
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

// ============================================================================
// MISIONES DIARIAS - Solo relacionadas con VISITAS
// ============================================================================
List<DailyMission> _generateDailyMissions() {
  return [
    const DailyMission(
      id: 'visit_casino_today',
      title: 'Visita un Casino',
      description: 'Acércate a cualquier casino Dreams hoy',
      icon: '🏛️',
      pointsReward: 100,
      targetValue: 1,
      currentValue: 0,
      progress: 0.0,
      type: MissionType.visit,
      rewardDescription: 'Bebida gratis',
    ),
    const DailyMission(
      id: 'visit_2_casinos_week',
      title: 'Explorador Semanal',
      description: 'Visita 2 casinos diferentes esta semana',
      icon: '🗺️',
      pointsReward: 200,
      targetValue: 2,
      currentValue: 0,
      progress: 0.0,
      type: MissionType.explore,
      rewardDescription: '3,000 Puntos Dreams',
    ),
    const DailyMission(
      id: 'maintain_streak',
      title: 'Mantén tu Racha',
      description: 'No pierdas tu racha de visitas',
      icon: '🔥',
      pointsReward: 50,
      targetValue: 1,
      currentValue: 0,
      progress: 0.0,
      type: MissionType.visit,
      rewardDescription: 'Multiplicador de puntos',
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
  final GamificationService _service = GamificationService();

  StreakNotifier() : super(const StreakData()) {
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final streak = await _service.getConsecutiveVisits();
    final lastVisit = await _service.getLastVisitDate();

    state = state.copyWith(
      currentStreak: streak,
      lastCheckIn: lastVisit,
      bonusMultiplier: _calculateMultiplier(streak),
    );
  }

  Future<void> registerVisit() async {
    final streak = await _service.updateStreak();
    final lastVisit = await _service.getLastVisitDate();

    final newWeek = List<bool>.from(state.weekProgress);
    final dayOfWeek = DateTime.now().weekday - 1;
    if (dayOfWeek >= 0 && dayOfWeek < 7) {
      newWeek[dayOfWeek] = true;
    }

    state = state.copyWith(
      currentStreak: streak,
      longestStreak:
          streak > state.longestStreak ? streak : state.longestStreak,
      lastCheckIn: lastVisit,
      weekProgress: newWeek,
      bonusMultiplier: _calculateMultiplier(streak),
    );
  }

  int _calculateMultiplier(int streak) {
    if (streak >= 30) return 5;
    if (streak >= 14) return 3;
    if (streak >= 7) return 2;
    return 1;
  }

  String getStreakReward() {
    if (state.currentStreak >= 30) return '🏨 Noche en Hotel Dreams';
    if (state.currentStreak >= 14) return '🍾 Botella de Champagne';
    if (state.currentStreak >= 7) return '🍽️ Cena para 2';
    if (state.currentStreak >= 3) return '🥂 Espumante';
    return '🍹 Próximo premio: 3 días seguidos';
  }
}

final streakProvider = StateNotifierProvider<StreakNotifier, StreakData>((ref) {
  return StreakNotifier();
});
