import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class DreamsManiaService extends StateNotifier<DreamsManiaState> {
  DreamsManiaService() : super(DreamsManiaState());

  Timer? _timer;

  void triggerEvent() {
    if (state.status != DreamsManiaStatus.inactive) return;

    // Start with Warning Phase (Alarm)
    state = state.copyWith(status: DreamsManiaStatus.warning);

    // After 3 seconds, start the game
    Future.delayed(const Duration(seconds: 3), () {
      _startGame();
    });
  }

  void startWarningPhase() => triggerEvent();

  void _startGame() {
    state = state.copyWith(
      status: DreamsManiaStatus.active,
      score: 0,
      timeLeft: 15,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft > 0) {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      } else {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    _timer?.cancel();
    state = state.copyWith(status: DreamsManiaStatus.finished);
  }

  void catchChip(int value) {
    if (state.status == DreamsManiaStatus.active) {
      state = state.copyWith(score: state.score + value);
    }
  }

  void reset() {
    _timer?.cancel();
    state = DreamsManiaState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final dreamsManiaProvider =
    StateNotifierProvider<DreamsManiaService, DreamsManiaState>((ref) {
  return DreamsManiaService();
});
