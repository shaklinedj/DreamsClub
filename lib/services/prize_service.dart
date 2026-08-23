import 'dart:convert';
import 'dart:math';
import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameRulesConfig {
  final int cooldownHours;
  final List<int> allowedDays; // 0=Sunday, 1=Monday, 2=Tuesday, 3=Wednesday, 4=Thursday, 5=Friday, 6=Saturday
  final bool timeWindowEnabled;
  final int startHour;
  final int endHour;
  final int minStreakRequired;
  final int maxDailyGamesAllowed;

  const GameRulesConfig({
    this.cooldownHours = 48,
    this.allowedDays = const [0, 1, 2, 3, 4, 5, 6],
    this.timeWindowEnabled = false,
    this.startHour = 0,
    this.endHour = 24,
    this.minStreakRequired = 0,
    this.maxDailyGamesAllowed = 1,
  });

  factory GameRulesConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const GameRulesConfig();

    final allowedDaysRaw = map['allowedDays'] as List?;
    final allowedDays = allowedDaysRaw != null
        ? allowedDaysRaw.map((e) => (e as num).toInt()).toList()
        : const [0, 1, 2, 3, 4, 5, 6];

    return GameRulesConfig(
      cooldownHours: (map['cooldownHours'] as num?)?.toInt() ?? 48,
      allowedDays: allowedDays,
      timeWindowEnabled: map['timeWindowEnabled'] as bool? ?? false,
      startHour: (map['startHour'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 24,
      minStreakRequired: (map['minStreakRequired'] as num?)?.toInt() ?? 0,
      maxDailyGamesAllowed: (map['maxDailyGamesAllowed'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cooldownHours': cooldownHours,
      'allowedDays': allowedDays,
      'timeWindowEnabled': timeWindowEnabled,
      'startHour': startHour,
      'endHour': endHour,
      'minStreakRequired': minStreakRequired,
      'maxDailyGamesAllowed': maxDailyGamesAllowed,
    };
  }
}

class PrizeService {
  static const String _keyPrizes = 'won_prizes';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generate collision-free, human-friendly uppercase code (e.g. DRM-7K9A2X)
  /// Excludes confusing characters like 0, O, 1, I.
  static String generateRedemptionCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random.secure();
    final randomCode = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    return 'DRM-$randomCode';
  }

  /// Stream of active prizes from Firestore catalog with fallback
  Stream<List<Prize>> streamPrizesCatalog() {
    return _firestore.collection('mini_game_prizes').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return mockPrizes;
      }
      final prizes = snapshot.docs
          .map((doc) => Prize.fromJson({'id': doc.id, ...doc.data()}))
          .where((p) => p.isActive)
          .toList();
      return prizes.isEmpty ? mockPrizes : prizes;
    });
  }

  /// Get active prizes catalog once
  Future<List<Prize>> getPrizesCatalog() async {
    try {
      final snapshot = await _firestore.collection('mini_game_prizes').get();
      if (snapshot.docs.isEmpty) {
        // Auto-seed default prizes if collection is empty
        _seedDefaultPrizes();
        return mockPrizes;
      }
      final prizes = snapshot.docs
          .map((doc) => Prize.fromJson({'id': doc.id, ...doc.data()}))
          .where((p) => p.isActive)
          .toList();
      return prizes.isEmpty ? mockPrizes : prizes;
    } catch (_) {
      return mockPrizes;
    }
  }

  Future<void> _seedDefaultPrizes() async {
    try {
      final batch = _firestore.batch();
      for (final prize in mockPrizes) {
        final docRef = _firestore.collection('mini_game_prizes').doc(prize.id);
        batch.set(docRef, prize.toJson());
      }
      await batch.commit();
    } catch (_) {}
  }

  /// Stream global rules configuration
  Stream<GameRulesConfig> streamRulesConfig() {
    return _firestore
        .collection('game_rules_config')
        .doc('global')
        .snapshots()
        .map((snapshot) => GameRulesConfig.fromMap(snapshot.data()));
  }

  /// Fetch global rules configuration once
  Future<GameRulesConfig> getRulesConfig() async {
    try {
      final doc = await _firestore.collection('game_rules_config').doc('global').get();
      if (!doc.exists) {
        const defaultConfig = GameRulesConfig();
        await _firestore
            .collection('game_rules_config')
            .doc('global')
            .set(defaultConfig.toMap());
        return defaultConfig;
      }
      return GameRulesConfig.fromMap(doc.data());
    } catch (_) {
      return const GameRulesConfig();
    }
  }

  /// Save a newly won prize to Firestore and local cache
  Future<void> saveWonPrize(WonPrize prize) async {
    try {
      // 1. Save to global user_prizes in Firestore
      await _firestore.collection('user_prizes').doc(prize.id).set(prize.toJson());

      // 2. Also save to user subcollection for quick rules evaluation
      if (prize.userId.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(prize.userId)
            .collection('prizes')
            .doc(prize.id)
            .set(prize.toJson());
      }
    } catch (_) {}

    // 3. Save locally in SharedPreferences for offline support
    final localPrizes = await getMyPrizes();
    localPrizes.removeWhere((p) => p.id == prize.id);
    localPrizes.insert(0, prize);
    await _savePrizesLocally(localPrizes);
  }

  /// Stream user prizes live from Firestore
  Stream<List<WonPrize>> streamUserPrizes(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    final queryIds = [userId];
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (currentUser.uid.isNotEmpty && !queryIds.contains(currentUser.uid)) {
        queryIds.add(currentUser.uid);
      }
      if (currentUser.email != null && currentUser.email!.isNotEmpty && !queryIds.contains(currentUser.email!)) {
        queryIds.add(currentUser.email!);
      }
    }

    return _firestore
        .collection('user_prizes')
        .where('userId', whereIn: queryIds)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => WonPrize.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
      list.sort((a, b) => b.wonAt.compareTo(a.wonAt));
      // Update local cache
      _savePrizesLocally(list);
      return list;
    });
  }

  /// Get all user's prizes (combining Firestore with local cache)
  Future<List<WonPrize>> getMyPrizes([String? userId]) async {
    final queryIds = <String>[];
    if (userId != null && userId.isNotEmpty) {
      queryIds.add(userId);
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      if (currentUser.uid.isNotEmpty && !queryIds.contains(currentUser.uid)) {
        queryIds.add(currentUser.uid);
      }
      if (currentUser.email != null && currentUser.email!.isNotEmpty && !queryIds.contains(currentUser.email!)) {
        queryIds.add(currentUser.email!);
      }
    }

    if (queryIds.isNotEmpty) {
      try {
        final snapshot = await _firestore
            .collection('user_prizes')
            .where('userId', whereIn: queryIds)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final list = snapshot.docs
              .map((doc) => WonPrize.fromJson({'id': doc.id, ...doc.data()}))
              .toList();
          list.sort((a, b) => b.wonAt.compareTo(a.wonAt));
          await _savePrizesLocally(list);
          return list;
        }
      } catch (_) {}
    }

    // Fallback to local SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? prizesJson = prefs.getString(_keyPrizes);
    if (prizesJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(prizesJson);
      final list = decoded.map((json) => WonPrize.fromJson(json)).toList();
      list.sort((a, b) => b.wonAt.compareTo(a.wonAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Get active prizes (status == 'disponible' and not expired)
  Future<List<WonPrize>> getActivePrizes([String? userId]) async {
    final allPrizes = await getMyPrizes(userId);
    return allPrizes.where((prize) => prize.isActive).toList();
  }

  /// Get redeemed prizes
  Future<List<WonPrize>> getRedeemedPrizes([String? userId]) async {
    final allPrizes = await getMyPrizes(userId);
    return allPrizes.where((prize) => prize.isRedeemed).toList();
  }

  /// Check 48h (or configured) cooldown eligibility for a user
  /// Returns null if eligible, or Duration remaining if locked
  Future<Duration?> checkCooldownRemaining(String userId, {int cooldownHours = 48}) async {
    final allPrizes = await getMyPrizes(userId);
    if (allPrizes.isEmpty) return null;

    final lastPrize = allPrizes.first; // Most recent won prize
    final now = DateTime.now();
    final cooldownEnd = lastPrize.wonAt.add(Duration(hours: cooldownHours));

    if (now.isBefore(cooldownEnd)) {
      return cooldownEnd.difference(now);
    }
    return null;
  }

  /// Internal: Save prizes list to SharedPreferences
  Future<void> _savePrizesLocally(List<WonPrize> prizes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prizes.map((p) => p.toJson()).toList();
      await prefs.setString(_keyPrizes, jsonEncode(jsonList));
    } catch (_) {}
  }
}
