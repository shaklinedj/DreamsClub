import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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

  DocumentReference<Map<String, dynamic>>? get _userRef {
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid);
  }

  Future<Map<String, dynamic>?> _readCloudState() async {
    final userRef = _userRef;
    if (userRef == null) return null;
    try {
      final data = (await userRef.get()).data()?['dailyBonus'];
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCloudState(DateTime date, int streak) async {
    final userRef = _userRef;
    if (userRef == null) return;
    try {
      await userRef.set({
        'dailyBonus': {
          'lastClaimDate': Timestamp.fromDate(date),
          'streak': streak,
        },
      }, SetOptions(merge: true));
    } catch (_) {
      // La caché local permite reclamar cuando no hay red.
    }
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastClaimIso = prefs.getString('last_daily_claim');
    final cloudState = await _readCloudState();
    final cloudDate = cloudState?['lastClaimDate'];
    final cloudStreak = cloudState?['streak'];
    final streak = cloudStreak is num
        ? cloudStreak.toInt()
        : prefs.getInt('daily_streak') ?? 0;

    DateTime? lastClaim;
    if (cloudDate is Timestamp) {
      lastClaim = cloudDate.toDate();
    } else if (lastClaimIso != null) {
      lastClaim = DateTime.parse(lastClaimIso);
    }

    if (lastClaim != null) {
      await prefs.setString('last_daily_claim', lastClaim.toIso8601String());
      await prefs.setInt('daily_streak', streak);
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
    await _writeCloudState(now, newStreak);

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
