import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class _CloudField {
  const _CloudField(this.available, this.value);

  final bool available;
  final dynamic value;
}

class GamificationService {
  static const String _achievementsKeyPrefix = 'gamification_achievements_';
  static const String _missionsKeyPrefix = 'gamification_missions_';
  static const String _pointsKeyPrefix = 'gamification_points_';
  static const String _visitedCasinosKeyPrefix = 'visited_casinos_';
  static const String _totalVisitsKeyPrefix = 'total_visits_';
  static const String _lastVisitDateKeyPrefix = 'last_visit_date_';
  static const String _consecutiveVisitsKeyPrefix = 'consecutive_visits_';
  static const String _visitHistoryKeyPrefix = 'visit_history_dates_';

  /// Mínimo de horas entre visitas válidas (24 horas = 1 día)
  static const int minimumHoursBetweenVisits = 24;

  String? get _uid {
    return firebase_auth.FirebaseAuth.instance.currentUser?.uid;
  }

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  /// Generate UID-specific cache key
  String _cacheKey(String prefix) {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return prefix;
    return '$prefix$uid';
  }

  Future<_CloudField> _readCloud(String field) async {
    final userRef = _userRef;
    if (userRef == null) return const _CloudField(false, null);
    try {
      final snapshot = await userRef.get();
      return _CloudField(true, snapshot.data()?[field]);
    } catch (_) {
      return const _CloudField(false, null);
    }
  }

  Future<void> _writeCloud(String field, dynamic value) async {
    final userRef = _userRef;
    if (userRef == null) return;
    try {
      if (field.contains('.')) {
        final parts = field.split('.');
        if (parts.length == 2) {
          final parentKey = parts[0];
          final childKey = parts[1];
          await userRef.set({
            parentKey: {
              childKey: value,
            }
          }, SetOptions(merge: true));
          return;
        }
      }
      await userRef.set({field: value}, SetOptions(merge: true));
    } catch (_) {
      // La caché local sigue disponible cuando no hay red.
    }
  }

  // ========== PUNTOS ==========
  Future<int> getTotalPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final cloudPoints = await _readCloud('points');
    if (cloudPoints.available) {
      final points = (cloudPoints.value as num?)?.toInt() ?? 0;
      await prefs.setInt(_cacheKey(_pointsKeyPrefix), points);
      return points;
    }
    return prefs.getInt(_cacheKey(_pointsKeyPrefix)) ?? 0;
  }

  Future<void> addPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getTotalPoints();
    final newTotal = current + points;
    await prefs.setInt(_cacheKey(_pointsKeyPrefix), newTotal);
    final userRef = _userRef;
    if (userRef != null) {
      try {
        await userRef.set({
          'points': newTotal,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ========== LOGROS ==========
  Future<Map<String, dynamic>> getAchievementData(String achievementId) async {
    final prefs = await SharedPreferences.getInstance();
    final userRef = _userRef;
    if (userRef != null) {
      try {
        final snapshot = await userRef.get();
        final docData = snapshot.data();
        if (docData != null) {
          final cloudAchievements = docData['gamificationAchievements'];
          if (cloudAchievements is Map && cloudAchievements[achievementId] is Map) {
            final cloudData = Map<String, dynamic>.from(
              cloudAchievements[achievementId] as Map,
            );
            await prefs.setString(
              _cacheKey('${_achievementsKeyPrefix}_$achievementId'),
              json.encode(cloudData),
            );
            return cloudData;
          }
          final legacyKey = 'gamificationAchievements.$achievementId';
          if (docData[legacyKey] is Map) {
            final cloudData = Map<String, dynamic>.from(docData[legacyKey] as Map);
            await prefs.setString(
              _cacheKey('${_achievementsKeyPrefix}_$achievementId'),
              json.encode(cloudData),
            );
            return cloudData;
          }
        }
      } catch (_) {}
    }
    final String? data =
        prefs.getString(_cacheKey('${_achievementsKeyPrefix}_$achievementId'));
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
      _cacheKey('${_achievementsKeyPrefix}_$achievementId'),
      json.encode(data),
    );
    await _writeCloud('gamificationAchievements.$achievementId', data);
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
    final cloudCasinos = await _readCloud('visitedCasinos');
    if (cloudCasinos.available) {
      final casinos = cloudCasinos.value is List
          ? cloudCasinos.value.whereType<String>().toSet()
          : <String>{};
      await prefs.setStringList(
          _cacheKey(_visitedCasinosKeyPrefix), casinos.toList());
      return casinos;
    }

    // Defensive: handle if cache is corrupted or wrong type
    try {
      final cached = prefs.get(_cacheKey(_visitedCasinosKeyPrefix));
      if (cached is List) {
        return cached.whereType<String>().toSet();
      }
    } catch (e) {
      // Ignore cache errors, clear and return empty
      await prefs.remove(_cacheKey(_visitedCasinosKeyPrefix));
    }

    return {};
  }

  Future<void> addVisitedCasino(String casinoId) async {
    final prefs = await SharedPreferences.getInstance();
    final visited = await getVisitedCasinos();
    visited.add(casinoId);
    await prefs.setStringList(
      _cacheKey(_visitedCasinosKeyPrefix),
      visited.toList(),
    );
    await _writeCloud('visitedCasinos', visited.toList());
  }

  Future<int> getTotalVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final cloudVisits = await _readCloud('totalVisits');
    if (cloudVisits.available) {
      final visits = (cloudVisits.value as num?)?.toInt() ?? 0;
      await prefs.setInt(_cacheKey(_totalVisitsKeyPrefix), visits);
      return visits;
    }
    return prefs.getInt(_cacheKey(_totalVisitsKeyPrefix)) ?? 0;
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
    final newTotal = current + 1;
    final history = await getVisitHistory()
      ..add(DateTime.now());
    final trimmedHistory =
        history.length > 100 ? history.sublist(history.length - 100) : history;
    final List<String> serializedHistory =
        trimmedHistory.map((date) => date.toIso8601String()).toList();

    final userRef = _userRef;
    if (userRef == null) {
      throw StateError('Debes iniciar sesión para registrar una visita.');
    }
    await userRef.set({
      'totalVisits': newTotal,
      'visitHistoryDates': serializedHistory,
    }, SetOptions(merge: true));

    await prefs.setInt(_cacheKey(_totalVisitsKeyPrefix), newTotal);
    await prefs.setStringList(
        _cacheKey(_visitHistoryKeyPrefix), serializedHistory);

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
    final cloudHistory = await _readCloud('visitHistoryDates');
    if (cloudHistory.available) {
      final rawHistory = cloudHistory.value;
      final List<dynamic> rawDates =
          rawHistory is List ? List<dynamic>.from(rawHistory) : const [];
      final List<DateTime> dates = rawDates
          .whereType<String>()
          .map(DateTime.tryParse)
          .whereType<DateTime>()
          .toList();
      final List<String> serializedDates =
          dates.map((date) => date.toIso8601String()).toList();
      await prefs.setStringList(
        _cacheKey(_visitHistoryKeyPrefix),
        serializedDates,
      );
      return dates;
    }

    // Defensive: handle if cache is corrupted or wrong type
    try {
      final cached = prefs.get(_cacheKey(_visitHistoryKeyPrefix));
      if (cached is List) {
        final dates = cached
            .whereType<String>()
            .map(DateTime.tryParse)
            .whereType<DateTime>()
            .toList();
        return dates;
      }
    } catch (e) {
      // Ignore cache errors, clear and return empty
      await prefs.remove(_cacheKey(_visitHistoryKeyPrefix));
    }

    return [];
  }

  /// Calcula qué días de la semana actual (Lunes=0 a Domingo=6) tienen visita
  Future<List<bool>> getCurrentWeekProgress() async {
    final history = await getVisitHistory();
    final now = DateTime.now();
    // En Dart, DateTime.weekday es 1 (Lunes) a 7 (Domingo).
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDate =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    final weekProgress = List<bool>.filled(7, false);

    for (final visit in history) {
      if (visit.isAfter(startOfWeekDate) ||
          visit.isAtSameMomentAs(startOfWeekDate)) {
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
    final cloudDate = await _readCloud('lastVisit');
    if (cloudDate.available && cloudDate.value is Timestamp) {
      final date = (cloudDate.value as Timestamp).toDate();
      await prefs.setString(
          _cacheKey(_lastVisitDateKeyPrefix), date.toIso8601String());
      return date;
    }
    if (cloudDate.available && cloudDate.value is String) {
      final date = DateTime.tryParse(cloudDate.value as String);
      if (date != null) {
        await prefs.setString(
            _cacheKey(_lastVisitDateKeyPrefix), date.toIso8601String());
        return date;
      }
    }
    final String? dateStr = prefs.getString(_cacheKey(_lastVisitDateKeyPrefix));
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      await prefs.remove(_cacheKey(_lastVisitDateKeyPrefix));
    }
    return date;
  }

  Future<void> setLastVisitDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _cacheKey(_lastVisitDateKeyPrefix), date.toIso8601String());
    await _writeCloud('lastVisit', Timestamp.fromDate(date));
  }

  Future<int> getConsecutiveVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final cloudStreak = await _readCloud('streak');
    if (cloudStreak.available) {
      final streak = (cloudStreak.value as num?)?.toInt() ?? 0;
      await prefs.setInt(_cacheKey(_consecutiveVisitsKeyPrefix), streak);
      return streak;
    }
    return prefs.getInt(_cacheKey(_consecutiveVisitsKeyPrefix)) ?? 0;
  }

  Future<void> setConsecutiveVisits(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheKey(_consecutiveVisitsKeyPrefix), count);
    final userRef = _userRef;
    if (userRef != null) {
      try {
        await userRef.set({
          'streak': count,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<int> getLongestStreak() async {
    final cloudStreak = await _readCloud('longestStreak');
    if (cloudStreak.available) {
      return (cloudStreak.value as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> setLongestStreak(int streak) async {
    await _writeCloud('longestStreak', streak);
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

    final longest = await getLongestStreak();
    if (currentStreak > longest) {
      await setLongestStreak(currentStreak);
    }

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
    final userRef = _userRef;
    if (userRef != null) {
      try {
        final snapshot = await userRef.get();
        final docData = snapshot.data();
        if (docData != null) {
          final cloudMissions = docData['gamificationMissions'];
          if (cloudMissions is Map && cloudMissions[missionId] is Map) {
            final cloudData = Map<String, dynamic>.from(
              cloudMissions[missionId] as Map,
            );
            await prefs.setString(
              _cacheKey('${_missionsKeyPrefix}_$missionId'),
              json.encode(cloudData),
            );
            return cloudData;
          }
          final legacyKey = 'gamificationMissions.$missionId';
          if (docData[legacyKey] is Map) {
            final cloudData = Map<String, dynamic>.from(docData[legacyKey] as Map);
            await prefs.setString(
              _cacheKey('${_missionsKeyPrefix}_$missionId'),
              json.encode(cloudData),
            );
            return cloudData;
          }
        }
      } catch (_) {}
    }
    final String? data =
        prefs.getString(_cacheKey('${_missionsKeyPrefix}_$missionId'));
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
      _cacheKey('${_missionsKeyPrefix}_$missionId'),
      json.encode(data),
    );
    await _writeCloud('gamificationMissions.$missionId', data);
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
