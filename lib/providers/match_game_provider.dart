import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/services/match_game_service.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';

/// State for the Match-3 game
class MatchGameState {
  final List<List<GemType?>> grid;
  final int score;
  final int movesLeft;
  final int level;
  final int targetScore;
  final int pendingPoints;
  final bool isAnimating;
  final bool levelComplete;
  final bool gameOver;
  final List<MatchResult> currentMatches;

  const MatchGameState({
    required this.grid,
    this.score = 0,
    this.movesLeft = 30,
    this.level = 1,
    this.targetScore = 500,
    this.pendingPoints = 0,
    this.isAnimating = false,
    this.levelComplete = false,
    this.gameOver = false,
    this.currentMatches = const [],
  });

  MatchGameState copyWith({
    List<List<GemType?>>? grid,
    int? score,
    int? movesLeft,
    int? level,
    int? targetScore,
    int? pendingPoints,
    bool? isAnimating,
    bool? levelComplete,
    bool? gameOver,
    List<MatchResult>? currentMatches,
  }) {
    return MatchGameState(
      grid: grid ?? this.grid,
      score: score ?? this.score,
      movesLeft: movesLeft ?? this.movesLeft,
      level: level ?? this.level,
      targetScore: targetScore ?? this.targetScore,
      pendingPoints: pendingPoints ?? this.pendingPoints,
      isAnimating: isAnimating ?? this.isAnimating,
      levelComplete: levelComplete ?? this.levelComplete,
      gameOver: gameOver ?? this.gameOver,
      currentMatches: currentMatches ?? this.currentMatches,
    );
  }
}

/// Result of a match
class MatchResult {
  final int row;
  final int col;
  final GemType gemType;

  const MatchResult({
    required this.row,
    required this.col,
    required this.gemType,
  });
}

/// Provider for Match-3 game state
class MatchGameNotifier extends StateNotifier<MatchGameState> {
  final Ref ref;
  final Random _random = Random();
  static const int gridSize = 8;

  MatchGameNotifier(this.ref) : super(const MatchGameState(grid: [])) {
    _initGame();
  }

  Future<void> _initGame() async {
    final level = await MatchGameService.getCurrentLevel();
    final pendingPoints = await MatchGameService.getPendingPoints();
    final config = MatchGameService.getLevelConfig(level);

    state = state.copyWith(
      level: level,
      pendingPoints: pendingPoints,
      targetScore: config.targetScore,
      movesLeft: config.moves,
    );

    _generateGrid();
  }

  void _generateGrid() {
    final newGrid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => _randomGem()),
    );

    // Ensure no initial matches
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        while (_hasMatchAt(newGrid, row, col)) {
          newGrid[row][col] = _randomGem();
        }
      }
    }

    state = state.copyWith(grid: newGrid, score: 0);
  }

  GemType _randomGem() {
    const gems = GemType.values;
    return gems[_random.nextInt(gems.length)];
  }

  bool _hasMatchAt(List<List<GemType?>> grid, int row, int col) {
    final gem = grid[row][col];
    if (gem == null) return false;

    // Check horizontal
    int horizontalCount = 1;
    for (int c = col - 1; c >= 0 && grid[row][c] == gem; c--) {
      horizontalCount++;
    }
    for (int c = col + 1; c < gridSize && grid[row][c] == gem; c++) {
      horizontalCount++;
    }

    // Check vertical
    int verticalCount = 1;
    for (int r = row - 1; r >= 0 && grid[r][col] == gem; r--) {
      verticalCount++;
    }
    for (int r = row + 1; r < gridSize && grid[r][col] == gem; r++) {
      verticalCount++;
    }

    return horizontalCount >= 3 || verticalCount >= 3;
  }

  /// Swap two gems and check for matches
  Future<void> swapGems(int row1, int col1, int row2, int col2) async {
    if (state.isAnimating || state.levelComplete || state.gameOver) return;

    // Only allow adjacent swaps
    if ((row1 - row2).abs() + (col1 - col2).abs() != 1) return;

    state = state.copyWith(isAnimating: true);

    // Perform swap
    final newGrid = List<List<GemType?>>.from(
      state.grid.map((row) => List<GemType?>.from(row)),
    );
    final temp = newGrid[row1][col1];
    newGrid[row1][col1] = newGrid[row2][col2];
    newGrid[row2][col2] = temp;

    // Check if swap creates a match
    if (_hasMatchAt(newGrid, row1, col1) || _hasMatchAt(newGrid, row2, col2)) {
      state = state.copyWith(
        grid: newGrid,
        movesLeft: state.movesLeft - 1,
      );

      // Process matches
      await _processMatches();
    } else {
      // Swap back - invalid move
      state = state.copyWith(isAnimating: false);
    }
  }

  Future<void> _processMatches() async {
    bool hasMatches = true;
    int totalMatchPoints = 0;
    final config = MatchGameService.getLevelConfig(state.level);

    while (hasMatches) {
      final matches = _findAllMatches();

      if (matches.isEmpty) {
        hasMatches = false;
        continue;
      }

      totalMatchPoints += matches.length * config.pointsPerMatch;

      // Remove matched gems
      final newGrid = List<List<GemType?>>.from(
        state.grid.map((row) => List<GemType?>.from(row)),
      );

      for (final match in matches) {
        newGrid[match.row][match.col] = null;
      }

      state = state.copyWith(
        grid: newGrid,
        currentMatches: matches,
      );

      // Wait for animation
      await Future.delayed(const Duration(milliseconds: 300));

      // Apply gravity
      _applyGravity(newGrid);

      // Fill empty spaces
      _fillEmptySpaces(newGrid);

      state = state.copyWith(
        grid: newGrid,
        currentMatches: [],
      );

      await Future.delayed(const Duration(milliseconds: 200));
    }

    // Update score
    final newScore = state.score + totalMatchPoints;
    state = state.copyWith(score: newScore);

    // Check for level completion
    if (newScore >= state.targetScore) {
      await _completeLevel(totalMatchPoints);
    } else if (state.movesLeft <= 0) {
      state = state.copyWith(gameOver: true, isAnimating: false);
    } else {
      state = state.copyWith(isAnimating: false);
    }
  }

  List<MatchResult> _findAllMatches() {
    final matches = <MatchResult>{};

    // Check horizontal matches
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize - 2; col++) {
        final gem = state.grid[row][col];
        if (gem == null) continue;

        if (state.grid[row][col + 1] == gem &&
            state.grid[row][col + 2] == gem) {
          matches.add(MatchResult(row: row, col: col, gemType: gem));
          matches.add(MatchResult(row: row, col: col + 1, gemType: gem));
          matches.add(MatchResult(row: row, col: col + 2, gemType: gem));

          // Check for longer matches
          for (int c = col + 3;
              c < gridSize && state.grid[row][c] == gem;
              c++) {
            matches.add(MatchResult(row: row, col: c, gemType: gem));
          }
        }
      }
    }

    // Check vertical matches
    for (int col = 0; col < gridSize; col++) {
      for (int row = 0; row < gridSize - 2; row++) {
        final gem = state.grid[row][col];
        if (gem == null) continue;

        if (state.grid[row + 1][col] == gem &&
            state.grid[row + 2][col] == gem) {
          matches.add(MatchResult(row: row, col: col, gemType: gem));
          matches.add(MatchResult(row: row + 1, col: col, gemType: gem));
          matches.add(MatchResult(row: row + 2, col: col, gemType: gem));

          // Check for longer matches
          for (int r = row + 3;
              r < gridSize && state.grid[r][col] == gem;
              r++) {
            matches.add(MatchResult(row: r, col: col, gemType: gem));
          }
        }
      }
    }

    return matches.toList();
  }

  void _applyGravity(List<List<GemType?>> grid) {
    for (int col = 0; col < gridSize; col++) {
      int writeRow = gridSize - 1;
      for (int row = gridSize - 1; row >= 0; row--) {
        if (grid[row][col] != null) {
          grid[writeRow][col] = grid[row][col];
          if (writeRow != row) {
            grid[row][col] = null;
          }
          writeRow--;
        }
      }
    }
  }

  void _fillEmptySpaces(List<List<GemType?>> grid) {
    for (int col = 0; col < gridSize; col++) {
      for (int row = 0; row < gridSize; row++) {
        if (grid[row][col] == null) {
          grid[row][col] = _randomGem();
        }
      }
    }
  }

  Future<void> _completeLevel(int earnedPoints) async {
    final authState = ref.read(authProvider);
    final isMember = authState.isMember;

    // Only add pending points if NOT a member
    if (!isMember) {
      final newPending = await MatchGameService.addPendingPoints(earnedPoints);
      state = state.copyWith(pendingPoints: newPending);
    } else {
      // Reward members with 1% of game points (100 pts per 10,000)
      final rewardPoints = (earnedPoints / 100).floor();
      if (rewardPoints > 0) {
        await ref.read(userProvider.notifier).addPoints(rewardPoints);
      }
    }

    // Advance to next level
    final nextLevel = state.level + 1;
    await MatchGameService.setCurrentLevel(nextLevel);
    await MatchGameService.updateHighScore(state.score);

    state = state.copyWith(
      levelComplete: true,
      isAnimating: false,
    );
  }

  void startNextLevel() {
    final nextLevel = state.level + 1;
    final config = MatchGameService.getLevelConfig(nextLevel);

    state = state.copyWith(
      level: nextLevel,
      targetScore: config.targetScore,
      movesLeft: config.moves,
      score: 0,
      levelComplete: false,
      gameOver: false,
    );

    _generateGrid();
  }

  void restartLevel() {
    final config = MatchGameService.getLevelConfig(state.level);

    state = state.copyWith(
      movesLeft: config.moves,
      score: 0,
      levelComplete: false,
      gameOver: false,
    );

    _generateGrid();
  }
}

final matchGameProvider =
    StateNotifierProvider.autoDispose<MatchGameNotifier, MatchGameState>((ref) {
  return MatchGameNotifier(ref);
});
