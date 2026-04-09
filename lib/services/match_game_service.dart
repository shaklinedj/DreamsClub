import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

/// Service for managing Match-3 game points and state
class MatchGameService {
  static const String _pendingPointsKey = 'match_game_pending_points';
  static const String _currentLevelKey = 'match_game_current_level';
  static const String _highScoreKey = 'match_game_high_score';
  static const int maxPendingPoints = 10000;

  /// Get pending points for non-members
  static Future<int> getPendingPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pendingPointsKey) ?? 0;
  }

  /// Add pending points (respects max limit)
  static Future<int> addPendingPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_pendingPointsKey) ?? 0;
    final newTotal = (current + points).clamp(0, maxPendingPoints);
    await prefs.setInt(_pendingPointsKey, newTotal);
    return newTotal;
  }

  /// Check if user has reached max pending points
  static Future<bool> hasReachedMaxPoints() async {
    final points = await getPendingPoints();
    return points >= maxPendingPoints;
  }

  /// Get current level
  static Future<int> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentLevelKey) ?? 1;
  }

  /// Set current level
  static Future<void> setCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentLevelKey, level);
  }

  /// Get high score
  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }

  /// Update high score if new score is higher
  static Future<void> updateHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt(_highScoreKey) ?? 0;
    if (score > currentHigh) {
      await prefs.setInt(_highScoreKey, score);
    }
  }

  /// Transfer pending points to member account in Firestore
  static Future<bool> transferPointsToMember(String userId) async {
    try {
      final pendingPoints = await getPendingPoints();
      if (pendingPoints <= 0) return true;

      // Update user's points in Firestore
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final currentPoints = (userDoc.data()?['points'] as num?)?.toInt() ?? 0;

        transaction.update(userRef, {
          'points': currentPoints + pendingPoints,
          'matchGamePointsTransferred': true,
          'matchGamePointsTransferredAt': FieldValue.serverTimestamp(),
          'matchGamePointsTransferredAmount': pendingPoints,
        });
      });

      // Clear pending points after successful transfer
      await clearPendingPoints();

      AppLogger.info(
          'Transferred $pendingPoints match game points to user $userId');
      return true;
    } catch (e) {
      AppLogger.error('Failed to transfer match game points', e);
      return false;
    }
  }

  /// Clear pending points (after transfer or reset)
  static Future<void> clearPendingPoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingPointsKey);
  }

  /// Get level configuration
  static LevelConfig getLevelConfig(int level) {
    if (level <= 5) {
      return const LevelConfig(
        targetScore: 500,
        pointsPerMatch: 10,
        moves: 30,
        gridSize: 8,
      );
    } else if (level <= 10) {
      return const LevelConfig(
        targetScore: 1000,
        pointsPerMatch: 15,
        moves: 25,
        gridSize: 8,
      );
    } else if (level <= 20) {
      return const LevelConfig(
        targetScore: 2000,
        pointsPerMatch: 20,
        moves: 20,
        gridSize: 8,
      );
    } else {
      return const LevelConfig(
        targetScore: 3000,
        pointsPerMatch: 25,
        moves: 15,
        gridSize: 8,
      );
    }
  }
}

/// Configuration for a game level
class LevelConfig {
  final int targetScore;
  final int pointsPerMatch;
  final int moves;
  final int gridSize;

  const LevelConfig({
    required this.targetScore,
    required this.pointsPerMatch,
    required this.moves,
    required this.gridSize,
  });
}

/// Gem types for the match-3 game
enum GemType {
  ruby, // Red
  sapphire, // Blue
  emerald, // Green
  gold, // Yellow
  amethyst, // Purple
  amber, // Orange
}

extension GemTypeExtension on GemType {
  String get emoji {
    switch (this) {
      case GemType.ruby:
        return '💎';
      case GemType.sapphire:
        return '🔷';
      case GemType.emerald:
        return '💚';
      case GemType.gold:
        return '⭐';
      case GemType.amethyst:
        return '🔮';
      case GemType.amber:
        return '🔶';
    }
  }

  int get colorValue {
    switch (this) {
      case GemType.ruby:
        return 0xFFE74C3C;
      case GemType.sapphire:
        return 0xFF3498DB;
      case GemType.emerald:
        return 0xFF2ECC71;
      case GemType.gold:
        return 0xFFF1C40F;
      case GemType.amethyst:
        return 0xFF9B59B6;
      case GemType.amber:
        return 0xFFE67E22;
    }
  }
}
