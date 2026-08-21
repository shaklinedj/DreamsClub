import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GamificationService {
  static const String _achievementsKey = 'gamification_achievements';
  static const String _missionsKey = 'gamification_missions';
  static const String _pointsKey = 'gamification_points';
  static const String _visitedCasinosKey = 'visited_casinos';
  static const String _totalVisitsKey = 'total_visits';
  static const String _lastVisitDateKey = 'last_visit_date';
  static const String _consecutiveVisitsKey = 'consecutive_visits';
  static const String _visitHistoryKey = 'visit_history_dates';

  /// Mínimo de horas entre visitas válidas (24 horas = 1 día)
  static const int minimumHoursBetweenVisits = 24;

  // ========== PUNTOS ==========
  Future<int> getTotalPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointsKey) ?? 0;
  }

  Future<void> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getTotalPoints();
    await prefs.setInt(_pointsKey, current + points);
  }

  // ========== LOGROS ==========
  Future<Map<String, dynamic>> getAchievementData(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('${_achievementsKey}_$achievementId');
    if (data == null) {
      return {
        'isUnlocked': false,
        'currentValue': 0,
        'progress': 0.0,
        'unlockedAt': null,
      };
    }
    return json.decode(data);
  }

  Future<void> saveAchievementData(
    String achievementId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_achievementsKey}_$achievementId',
      json.encode(data),
    );
  }

  Future<void> unlockAchievement(String achievementId, int pointsReward) async {
    final data = {
      'isUnlocked': true,
      'unlockedAt': DateTime.now().toIso8601String(),
      'progress': 1.0,
    };
    await saveAchievementData(achievementId, data);
    await addPoints(pointsReward);
  }

  Future<void> updateAchievementProgress(
    String achievementId,
    int currentValue,
    int targetValue,
  ) async {
    final progress = (currentValue / targetValue).clamp(0.0, 1.0);
    final data = await getAchievementData(achievementId);
    data['currentValue'] = currentValue;
    data['progress'] = progress;

    if (currentValue >= targetValue) {
      if (!(data['isUnlocked'] ?? false)) {
        data['isUnlocked'] = true;
        data['unlockedAt'] = DateTime.now().toIso8601String();
      }
    } else {
      data['isUnlocked'] = false;
      data['unlockedAt'] = null;
    }

    await saveAchievementData(achievementId, data);
  }

  // ========== VISITAS A CASINOS ==========
  Future<Set<String>> getVisitedCasinos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? casinos = prefs.getStringList(_visitedCasinosKey);
    if (casinos == null) return {};
    return casinos.toSet();
  }

  Future<void> addVisitedCasino(String casinoId) async {
    final prefs = await SharedPreferences.getInstance();
    final visited = await getVisitedCasinos();
    visited.add(casinoId);
    await prefs.setStringList(
      _visitedCasinosKey,
      visited.toList(),
    );
  }

  Future<int> getTotalVisits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalVisitsKey) ?? 0;
  }

  /// Verifica si han pasado al menos 24 horas desde la última visita registrada.
  /// Retorna true si la visita es válida (nuevo día), false si ya visitó hoy.
  Future<bool> isVisitValid() async {
    final lastVisit = await getLastVisitDate();
    if (lastVisit == null) return true; // Primera visita siempre es válida

    final now = DateTime.now();
    final hoursDiff = now.difference(lastVisit).inHours;

    // Verificar si han pasado al menos 24 horas O si es un día calendario diferente
    final isDifferentDay = _daysBetween(lastVisit, now) >= 1;
    final hasEnoughHours = hoursDiff >= minimumHoursBetweenVisits;

    return isDifferentDay || hasEnoughHours;
  }

  /// Incrementa las visitas totales SOLO si han pasado al menos 24 horas.
  /// Retorna true si la visita fue registrada, false si fue rechazada.
  Future<bool> incrementTotalVisitsIfValid() async {
    final isValid = await isVisitValid();

    if (!isValid) {
      // Ya visitó hoy, no contar esta visita
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await getTotalVisits();
    await prefs.setInt(_totalVisitsKey, current + 1);

    // Guardar en historial de visitas
    await _addVisitToHistory(DateTime.now());

    return true;
  }

  /// Método legacy para compatibilidad - DEPRECATED
  /// Usar incrementTotalVisitsIfValid() en su lugar
  @Deprecated(
      'Use incrementTotalVisitsIfValid() instead for proper 24h validation')
  Future<void> incrementTotalVisits() async {
    // Ahora valida antes de incrementar
    await incrementTotalVisitsIfValid();
  }

  /// Obtiene el historial de fechas de visitas válidas
  Future<List<DateTime>> getVisitHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? dates = prefs.getStringList(_visitHistoryKey);
    if (dates == null) return [];
    return dates.map((d) => DateTime.parse(d)).toList();
  }

  /// Agrega una visita al historial
  Future<void> _addVisitToHistory(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getVisitHistory();
    history.add(date);

    // Mantener solo los últimos 100 registros para no ocupar mucho espacio
    final trimmed =
        history.length > 100 ? history.sublist(history.length - 100) : history;

    await prefs.setStringList(
      _visitHistoryKey,
      trimmed.map((d) => d.toIso8601String()).toList(),
    );
  }

  /// Calcula qué días de la semana actual (Lunes=0 a Domingo=6) tienen visita
  Future<List<bool>> getCurrentWeekProgress() async {
    final history = await getVisitHistory();
    final now = DateTime.now();
    // En Dart, DateTime.weekday es 1 (Lunes) a 7 (Domingo).
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final weekProgress = List<bool>.filled(7, false);

    for (final visit in history) {
      if (visit.isAfter(startOfWeekDate) || visit.isAtSameMomentAs(startOfWeekDate)) {
        final dayIndex = visit.weekday - 1;
        if (dayIndex >= 0 && dayIndex < 7) {
          weekProgress[dayIndex] = true;
        }
      }
    }
    return weekProgress;
  }

  // ========== RACHA DE VISITAS ==========
  Future<DateTime?> getLastVisitDate() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dateStr = prefs.getString(_lastVisitDateKey);
    if (dateStr == null) return null;
    return DateTime.parse(dateStr);
  }

  Future<void> setLastVisitDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastVisitDateKey, date.toIso8601String());
  }

  Future<int> getConsecutiveVisits() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_consecutiveVisitsKey) ?? 0;
  }

  Future<void> setConsecutiveVisits(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_consecutiveVisitsKey, count);
  }

  Future<int> updateStreak() async {
    final now = DateTime.now();
    final lastVisit = await getLastVisitDate();
    int currentStreak = await getConsecutiveVisits();

    if (lastVisit == null) {
      // Primera visita
      currentStreak = 1;
    } else {
      final daysDiff = _daysBetween(lastVisit, now);

      if (daysDiff == 0) {
        // Ya visitó hoy, no cambiar racha
        return currentStreak;
      } else if (daysDiff == 1) {
        // Día consecutivo
        currentStreak++;
      } else {
        // Se rompió la racha
        currentStreak = 1;
      }
    }

    await setConsecutiveVisits(currentStreak);
    await setLastVisitDate(now);
    return currentStreak;
  }

  int _daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  // ========== MISIONES DIARIAS ==========
  Future<Map<String, dynamic>> getMissionData(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('${_missionsKey}_$missionId');
    if (data == null) {
      return {
        'isCompleted': false,
        'currentValue': 0,
        'progress': 0.0,
        'date': DateTime.now().toIso8601String().split('T')[0],
      };
    }
    final decoded = json.decode(data);

    // Verificar si es del día actual
    final savedDate = decoded['date'] as String;
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (savedDate != today) {
      // Resetear misión para el nuevo día
      return {
        'isCompleted': false,
        'currentValue': 0,
        'progress': 0.0,
        'date': today,
      };
    }

    return decoded;
  }

  Future<void> saveMissionData(
    String missionId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_missionsKey}_$missionId',
      json.encode(data),
    );
  }

  Future<void> updateMissionProgress(
    String missionId,
    int currentValue,
    int targetValue,
  ) async {
    final progress = (currentValue / targetValue).clamp(0.0, 1.0);
    final data = await getMissionData(missionId);
    data['currentValue'] = currentValue;
    data['progress'] = progress;
    data['isCompleted'] = currentValue >= targetValue;

    await saveMissionData(missionId, data);
  }

  // ========== VERIFICACIÓN DE LOGROS ==========
  Future<List<Map<String, dynamic>>> checkAndUnlockVisitAchievements() async {
    final totalVisits = await getTotalVisits();
    final uniqueCasinos = (await getVisitedCasinos()).length;
    final streak = await getConsecutiveVisits();

    final List<Map<String, dynamic>> unlockedAchievements = [];

    // Logros de visitas totales
    final achievementsToCheck = [
      {
        'id': 'first_casino_visit',
        'target': 1,
        'value': totalVisits,
        'title': 'Bienvenido a Dreams',
        'points': 100
      },
      {
        'id': 'total_10_visits',
        'target': 10,
        'value': totalVisits,
        'title': 'Habitué',
        'points': 200
      },
      {
        'id': 'total_50_visits',
        'target': 50,
        'value': totalVisits,
        'title': 'VIP Dreams',
        'points': 1000
      },
      {
        'id': 'total_100_visits',
        'target': 100,
        'value': totalVisits,
        'title': 'Leyenda Dreams',
        'points': 5000
      },

      // Logros de casinos diferentes
      {
        'id': 'visit_2_casinos',
        'target': 2,
        'value': uniqueCasinos,
        'title': 'Explorador',
        'points': 500
      },
      {
        'id': 'visit_all_casinos',
        'target': 5,
        'value': uniqueCasinos,
        'title': 'Coleccionista Dreams',
        'points': 5000
      },

      // Logros de racha
      {
        'id': 'visit_3_days',
        'target': 3,
        'value': streak,
        'title': 'Visitante Frecuente',
        'points': 300
      },
      {
        'id': 'visit_7_days',
        'target': 7,
        'value': streak,
        'title': 'Guerrero Semanal',
        'points': 700
      },
      {
        'id': 'visit_30_days',
        'target': 30,
        'value': streak,
        'title': 'Leyenda Mensual',
        'points': 3000
      },
    ];

    for (final achievement in achievementsToCheck) {
      final id = achievement['id'] as String;
      final target = achievement['target'] as int;
      final value = achievement['value'] as int;
      final title = achievement['title'] as String;
      final points = achievement['points'] as int;

      if (value >= target) {
        // Changed == to >= to catch missed achievements
        // Verificar si ya fue desbloqueado
        final data = await getAchievementData(id);
        final isUnlocked = data['isUnlocked'] ?? false;

        if (!isUnlocked) {
          // Desbloquear
          await unlockAchievement(id, points);
          unlockedAchievements.add({
            'id': id,
            'title': title,
            'points': points,
          });
        }
      }
    }

    return unlockedAchievements;
  }

  // ========== RESET ==========
  Future<void> resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
