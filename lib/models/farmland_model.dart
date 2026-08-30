import 'package:cloud_firestore/cloud_firestore.dart';

class FarmlandState {
  final int waterDrops;
  final double cropProgress;
  final String cropType;
  final int rewardPoints;
  final DateTime? lastDailyCheckin;
  final DateTime? lastBucketClaim;
  final Map<String, bool> completedTasks;
  final int totalHarvests;
  final int level;

  const FarmlandState({
    this.waterDrops = 80,
    this.cropProgress = 0.0,
    this.cropType = 'Trigo Dorado',
    this.rewardPoints = 500,
    this.lastDailyCheckin,
    this.lastBucketClaim,
    this.completedTasks = const {},
    this.totalHarvests = 0,
    this.level = 1,
  });

  bool get canClaimDaily {
    if (lastDailyCheckin == null) return true;
    final now = DateTime.now();
    return lastDailyCheckin!.year != now.year ||
        lastDailyCheckin!.month != now.month ||
        lastDailyCheckin!.day != now.day;
  }

  bool get canClaimBucket {
    if (lastBucketClaim == null) return true;
    final diff = DateTime.now().difference(lastBucketClaim!);
    return diff.inHours >= 3;
  }

  Duration get bucketTimeRemaining {
    if (lastBucketClaim == null) return Duration.zero;
    final nextClaim = lastBucketClaim!.add(const Duration(hours: 3));
    final diff = nextClaim.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  int get growthStage {
    if (cropProgress >= 100.0) return 4; // Lista para cosechar
    if (cropProgress >= 75.0) return 3; // Planta dorada madura
    if (cropProgress >= 40.0) return 2; // Brote verde crecer
    if (cropProgress >= 10.0) return 1; // Germinando
    return 0; // Semilla recién plantada
  }

  FarmlandState copyWith({
    int? waterDrops,
    double? cropProgress,
    String? cropType,
    int? rewardPoints,
    DateTime? lastDailyCheckin,
    DateTime? lastBucketClaim,
    Map<String, bool>? completedTasks,
    int? totalHarvests,
    int? level,
  }) {
    return FarmlandState(
      waterDrops: waterDrops ?? this.waterDrops,
      cropProgress: cropProgress ?? this.cropProgress,
      cropType: cropType ?? this.cropType,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      lastDailyCheckin: lastDailyCheckin ?? this.lastDailyCheckin,
      lastBucketClaim: lastBucketClaim ?? this.lastBucketClaim,
      completedTasks: completedTasks ?? this.completedTasks,
      totalHarvests: totalHarvests ?? this.totalHarvests,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waterDrops': waterDrops,
      'cropProgress': cropProgress,
      'cropType': cropType,
      'rewardPoints': rewardPoints,
      'lastDailyCheckin': lastDailyCheckin != null
          ? Timestamp.fromDate(lastDailyCheckin!)
          : null,
      'lastBucketClaim':
          lastBucketClaim != null ? Timestamp.fromDate(lastBucketClaim!) : null,
      'completedTasks': completedTasks,
      'totalHarvests': totalHarvests,
      'level': level,
    };
  }

  factory FarmlandState.fromMap(Map<String, dynamic> map) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return FarmlandState(
      waterDrops: (map['waterDrops'] as num?)?.toInt() ?? 80,
      cropProgress: (map['cropProgress'] as num?)?.toDouble() ?? 0.0,
      cropType: map['cropType'] as String? ?? 'Trigo Dorado',
      rewardPoints: (map['rewardPoints'] as num?)?.toInt() ?? 500,
      lastDailyCheckin: parseDateTime(map['lastDailyCheckin']),
      lastBucketClaim: parseDateTime(map['lastBucketClaim']),
      completedTasks: (map['completedTasks'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          {},
      totalHarvests: (map['totalHarvests'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
    );
  }
}
