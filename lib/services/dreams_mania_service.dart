import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/providers/game_history_provider.dart';

enum DreamsManiaStatus { inactive, warning, active, finished }

class DreamsManiaState {
  final DreamsManiaStatus status;
  final int score;
  final int timeLeft;

  DreamsManiaState({
    this.status = DreamsManiaStatus.inactive,
    this.score = 0,
    this.timeLeft = 0,
  });

  DreamsManiaState copyWith({
    DreamsManiaStatus? status,
    int? score,
    int? timeLeft,
  }) {
    return DreamsManiaState(
      status: status ?? this.status,
      score: score ?? this.score,
      timeLeft: timeLeft ?? this.timeLeft,
    );
  }
}

/// Simplified Dreams Mania Service.
/// Game availability (frequency, location, etc.) is handled by gameAvailabilityProvider.
/// This service only manages the game state once started.
class DreamsManiaService extends StateNotifier<DreamsManiaState> {
  DreamsManiaService(this.ref) : super(DreamsManiaState());

  final Ref ref;
  Timer? _gameTimer;

  static const int gameDurationSeconds = 15;

  /// Start the game (called from home screen launcher).
  /// Availability check should be done by caller using gameAvailabilityProvider.
  void startGame() {
    // Start with Warning Phase (Alarm) for 3 seconds
    state = state.copyWith(status: DreamsManiaStatus.warning);

    // After 3 seconds, switch to active game
    Future.delayed(const Duration(seconds: 3), () {
      _startActivePhase();
    });
  }

  /// Alias for compatibility
  void triggerEvent() => startGame();
  void startWarningPhase() => startGame();

  void _startActivePhase() {
    state = state.copyWith(
      status: DreamsManiaStatus.active,
      score: 0,
      timeLeft: gameDurationSeconds,
    );

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        _finishGame();
      }
    });
  }

  Future<void> _finishGame() async {
    _gameTimer?.cancel();
    _gameTimer = null;

    state = state.copyWith(status: DreamsManiaStatus.finished);

    // Add points to user
    if (state.score > 0) {
      ref.read(userProvider.notifier).addPoints(state.score);
    }

    // Record play in game history (for Firebase frequency rules)
    ref.read(gameHistoryProvider.notifier).recordPlay('dreams_mania');
  }

  /// Called when user taps a falling chip
  void catchChip(int value) {
    if (state.status == DreamsManiaStatus.active) {
      state = state.copyWith(score: state.score + value);
    }
  }

  /// Reset game to inactive state
  void reset() {
    _gameTimer?.cancel();
    _gameTimer = null;
    state = DreamsManiaState();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

final dreamsManiaProvider =
    StateNotifierProvider<DreamsManiaService, DreamsManiaState>((ref) {
  return DreamsManiaService(ref);
});
