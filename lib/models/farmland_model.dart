import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CropInfo {
  final String id;
  final String name;
  final String emoji;
  final int rewardPoints;
  final String description;
  final int requiredLevel;
  final Color primaryColor;

  const CropInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.rewardPoints,
    required this.description,
    this.requiredLevel = 1,
    this.primaryColor = const Color(0xFFF59E0B),
  });
}

const List<CropInfo> kAvailableCrops = [
  CropInfo(
    id: 'trigo',
    name: 'Trigo Dorado',
    emoji: '🌾',
    rewardPoints: 500,
    description: 'Rápido crecimiento y excelentes espigas doradas.',
    requiredLevel: 1,
    primaryColor: Color(0xFFEAB308),
  ),
  CropInfo(
    id: 'maiz',
    name: 'Maíz Dulce',
    emoji: '🌽',
    rewardPoints: 750,
    description: 'Mazorcas jugosas llenas de energía Dreams.',
    requiredLevel: 1,
    primaryColor: Color(0xFFFBBF24),
  ),
  CropInfo(
    id: 'zanahoria',
    name: 'Zanahoria Gigante',
    emoji: '🥕',
    rewardPoints: 1000,
    description: 'Crujiente y nutritiva, el orgullo de la huerta.',
    requiredLevel: 2,
    primaryColor: Color(0xFFF97316),
  ),
  CropInfo(
    id: 'fresa',
    name: 'Fresas Silvestres',
    emoji: '🍓',
    rewardPoints: 1500,
    description: 'Frutas australes dulces y muy codiciadas.',
    requiredLevel: 3,
    primaryColor: Color(0xFFEF4444),
  ),
  CropInfo(
    id: 'manzano',
    name: 'Manzano Real',
    emoji: '🍎',
    rewardPoints: 2000,
    description: 'Árbol frutal legendario con abundantes frutos.',
    requiredLevel: 4,
    primaryColor: Color(0xFFDC2626),
  ),
];

class FarmlandState {
  final int waterDrops;
  final double cropProgress;
  final String cropType;
  final String cropId;
  final int rewardPoints;
  final int fertilizerCount;
  final DateTime? lastDailyCheckin;
  final DateTime? lastBucketClaim;
  final Map<String, bool> completedTasks;
  final Map<String, int> animalPetCount;
  final int totalHarvests;
  final int level;

  const FarmlandState({
    this.waterDrops = 80,
    this.cropProgress = 0.0,
    this.cropType = 'Trigo Dorado',
    this.cropId = 'trigo',
    this.rewardPoints = 500,
    this.fertilizerCount = 2,
    this.lastDailyCheckin,
    this.lastBucketClaim,
    this.completedTasks = const {},
    this.animalPetCount = const {},
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
    if (cropProgress >= 100.0) return 4; // Cosecha lista (fruto completo)
    if (cropProgress >= 75.0) return 3; // Planta madura con flores/frutos jóvenes
    if (cropProgress >= 40.0) return 2; // Planta joven con hojas verdes
    if (cropProgress >= 10.0) return 1; // Germinando brote tierno
    return 0; // Semilla plantada en tierra fértil
  }

  CropInfo get currentCropInfo {
    return kAvailableCrops.firstWhere(
      (c) => c.id == cropId || c.name == cropType,
      orElse: () => kAvailableCrops.first,
    );
  }

  FarmlandState copyWith({
    int? waterDrops,
    double? cropProgress,
    String? cropType,
    String? cropId,
    int? rewardPoints,
    int? fertilizerCount,
    DateTime? lastDailyCheckin,
    DateTime? lastBucketClaim,
    Map<String, bool>? completedTasks,
    Map<String, int>? animalPetCount,
    int? totalHarvests,
    int? level,
  }) {
    return FarmlandState(
      waterDrops: waterDrops ?? this.waterDrops,
      cropProgress: cropProgress ?? this.cropProgress,
      cropType: cropType ?? this.cropType,
      cropId: cropId ?? this.cropId,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      fertilizerCount: fertilizerCount ?? this.fertilizerCount,
      lastDailyCheckin: lastDailyCheckin ?? this.lastDailyCheckin,
      lastBucketClaim: lastBucketClaim ?? this.lastBucketClaim,
      completedTasks: completedTasks ?? this.completedTasks,
      animalPetCount: animalPetCount ?? this.animalPetCount,
      totalHarvests: totalHarvests ?? this.totalHarvests,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'waterDrops': waterDrops,
      'cropProgress': cropProgress,
      'cropType': cropType,
      'cropId': cropId,
      'rewardPoints': rewardPoints,
      'fertilizerCount': fertilizerCount,
      'lastDailyCheckin': lastDailyCheckin != null
          ? Timestamp.fromDate(lastDailyCheckin!)
          : null,
      'lastBucketClaim':
          lastBucketClaim != null ? Timestamp.fromDate(lastBucketClaim!) : null,
      'completedTasks': completedTasks,
      'animalPetCount': animalPetCount,
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

    final cropName = map['cropType'] as String? ?? 'Trigo Dorado';
    final cropId = map['cropId'] as String? ??
        (cropName.toLowerCase().contains('ma')
            ? (cropName.toLowerCase().contains('maiz') ? 'maiz' : 'manzano')
            : (cropName.toLowerCase().contains('zan')
                ? 'zanahoria'
                : (cropName.toLowerCase().contains('fres')
                    ? 'fresa'
                    : 'trigo')));

    return FarmlandState(
      waterDrops: (map['waterDrops'] as num?)?.toInt() ?? 80,
      cropProgress: (map['cropProgress'] as num?)?.toDouble() ?? 0.0,
      cropType: cropName,
      cropId: cropId,
      rewardPoints: (map['rewardPoints'] as num?)?.toInt() ?? 500,
      fertilizerCount: (map['fertilizerCount'] as num?)?.toInt() ?? 2,
      lastDailyCheckin: parseDateTime(map['lastDailyCheckin']),
      lastBucketClaim: parseDateTime(map['lastBucketClaim']),
      completedTasks: (map['completedTasks'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as bool),
          ) ??
          {},
      animalPetCount: (map['animalPetCount'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      totalHarvests: (map['totalHarvests'] as num?)?.toInt() ?? 0,
      level: (map['level'] as num?)?.toInt() ?? 1,
    );
  }
}
