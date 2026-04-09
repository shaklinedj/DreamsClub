// Modelo de Logros
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int pointsReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final double progress; // 0.0 a 1.0
  final int currentValue;
  final int targetValue;
  final AchievementCategory category;
  final String? rewardDescription; // Descripción del premio físico

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsReward,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0.0,
    this.currentValue = 0,
    required this.targetValue,
    required this.category,
    this.rewardDescription,
  });

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    double? progress,
    int? currentValue,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      pointsReward: pointsReward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue,
      category: category,
      rewardDescription: rewardDescription,
    );
  }
}

enum AchievementCategory { visits, exploration, special }

// Modelo de Misiones Diarias
class DailyMission {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int pointsReward;
  final bool isCompleted;
  final double progress;
  final int currentValue;
  final int targetValue;
  final MissionType type;
  final String? rewardDescription;

  const DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsReward,
    this.isCompleted = false,
    this.progress = 0.0,
    this.currentValue = 0,
    required this.targetValue,
    required this.type,
    this.rewardDescription,
  });

  DailyMission copyWith({
    bool? isCompleted,
    double? progress,
    int? currentValue,
  }) {
    return DailyMission(
      id: id,
      title: title,
      description: description,
      icon: icon,
      pointsReward: pointsReward,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue,
      type: type,
      rewardDescription: rewardDescription,
    );
  }
}

enum MissionType { visit, explore }

// Modelo de Racha
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCheckIn;
  final List<bool> weekProgress; // 7 días
  final int bonusMultiplier;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCheckIn,
    this.weekProgress = const [false, false, false, false, false, false, false],
    this.bonusMultiplier = 1,
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCheckIn,
    List<bool>? weekProgress,
    int? bonusMultiplier,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCheckIn: lastCheckIn ?? this.lastCheckIn,
      weekProgress: weekProgress ?? this.weekProgress,
      bonusMultiplier: bonusMultiplier ?? this.bonusMultiplier,
    );
  }
}
