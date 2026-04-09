import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyBonusProvider =
    StateNotifierProvider<DailyBonusNotifier, DailyBonusState>((ref) {
  return DailyBonusNotifier();
});

class DailyBonusState {
  final bool canClaim;
  final int currentStreak;
  final DateTime? lastClaimDate;
  final bool hasShownSession;

  DailyBonusState({
    this.canClaim = false,
    this.currentStreak = 0,
    this.lastClaimDate,
    this.hasShownSession = false,
  });

  DailyBonusState copyWith({
    bool? canClaim,
    int? currentStreak,
    DateTime? lastClaimDate,
    bool? hasShownSession,
  }) {
    return DailyBonusState(
      canClaim: canClaim ?? this.canClaim,
      currentStreak: currentStreak ?? this.currentStreak,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      hasShownSession: hasShownSession ?? this.hasShownSession,
    );
  }
}

class DailyBonusNotifier extends StateNotifier<DailyBonusState> {
  DailyBonusNotifier() : super(DailyBonusState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimIso = prefs.getString('last_daily_claim');
    final streak = prefs.getInt('daily_streak') ?? 0;

    DateTime? lastClaim;
    if (lastClaimIso != null) {
      lastClaim = DateTime.parse(lastClaimIso);
    }

    final now = DateTime.now();
    bool canClaim = true;

    if (lastClaim != null) {
      final difference = now.difference(lastClaim).inDays;
      if (difference == 0 && now.day == lastClaim.day) {
        canClaim = false;
      } else if (difference > 1) {
        // Reset streak if missed a day
        // (Optional: logic could be more forgiving)
      }
    }

    state = DailyBonusState(
      canClaim: canClaim,
      currentStreak: streak,
      lastClaimDate: lastClaim,
      hasShownSession: false,
    );
  }

  void markAsShown() {
    state = state.copyWith(hasShownSession: true);
  }

  Future<int> claimBonus() async {
    if (!state.canClaim) return 0;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Calculate new streak
    int newStreak = state.currentStreak + 1;
    // If missed more than 1 day (approx), reset streak logic could go here,
    // but for now we just increment to make it addictive.

    await prefs.setString('last_daily_claim', now.toIso8601String());
    await prefs.setInt('daily_streak', newStreak);

    state = DailyBonusState(
      canClaim: false,
      currentStreak: newStreak,
      lastClaimDate: now,
      hasShownSession: true,
    );

    // Return points earned (random or fixed based on streak)
    return 100 + (newStreak * 10);
  }
}
