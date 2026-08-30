import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casinoloyalty_flutter/models/farmland_model.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';

final farmlandProvider =
    StateNotifierProvider<FarmlandNotifier, FarmlandState>((ref) {
  final uid =
      ref.watch(authProvider.select((state) => state.firebaseUser?.uid));
  return FarmlandNotifier(ref, uid ?? '');
});

class FarmlandNotifier extends StateNotifier<FarmlandState> {
  final Ref _ref;
  final String _uid;
  StreamSubscription<DocumentSnapshot>? _subscription;

  FarmlandNotifier(this._ref, this._uid) : super(const FarmlandState()) {
    if (_uid.isNotEmpty) {
      _initListen();
    }
  }

  void _initListen() {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('farmland')
        .doc('current_state');

    _subscription = docRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        state = FarmlandState.fromMap(snapshot.data()!);
      } else {
        // Initialize state in Firestore if missing
        _saveToFirestore(state);
      }
    }, onError: (e) {
      AppLogger.error('Error escuchando estado Farmland: $e');
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _saveToFirestore(FarmlandState newState) async {
    state = newState;
    if (_uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('farmland')
          .doc('current_state')
          .set(newState.toMap(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('Error guardando Farmland en Firestore: $e');
    }
  }

  /// Regar el cultivo actual consumiendo 10 gotas de agua
  Future<bool> waterCrop() async {
    if (state.waterDrops < 10) return false;
    if (state.cropProgress >= 100.0) return false;

    // Curva psicológica de progreso (Farmland mechanics)
    double increment;
    final current = state.cropProgress;
    if (current < 30.0) {
      increment = 10.0;
    } else if (current < 60.0) {
      increment = 5.0;
    } else if (current < 85.0) {
      increment = 2.0;
    } else if (current < 95.0) {
      increment = 0.5;
    } else if (current < 99.0) {
      increment = 0.2;
    } else {
      increment = 0.1;
    }

    final newProgress = (current + increment).clamp(0.0, 100.0);
    final newWater = state.waterDrops - 10;

    final updatedState = state.copyWith(
      waterDrops: newWater,
      cropProgress: newProgress,
    );

    await _saveToFirestore(updatedState);
    return true;
  }

  /// Reclamar check-in diario de agua (+50 gotas)
  Future<bool> claimDailyWater() async {
    if (!state.canClaimDaily) return false;

    final updatedState = state.copyWith(
      waterDrops: state.waterDrops + 50,
      lastDailyCheckin: DateTime.now(),
    );

    await _saveToFirestore(updatedState);
    return true;
  }

  /// Reclamar el cubo de agua temporal (+20 gotas cada 3 horas)
  Future<bool> claimBucketWater() async {
    if (!state.canClaimBucket) return false;

    final updatedState = state.copyWith(
      waterDrops: state.waterDrops + 20,
      lastBucketClaim: DateTime.now(),
    );

    await _saveToFirestore(updatedState);
    return true;
  }

  /// Completar misión diaria y ganar agua
  Future<bool> completeTask(String taskId, int waterReward) async {
    if (state.completedTasks[taskId] == true) return false;

    final newTasks = Map<String, bool>.from(state.completedTasks);
    newTasks[taskId] = true;

    final updatedState = state.copyWith(
      waterDrops: state.waterDrops + waterReward,
      completedTasks: newTasks,
    );

    await _saveToFirestore(updatedState);
    return true;
  }

  /// Cosechar al llegar al 100% y reclamar los Puntos Dreams
  Future<bool> harvestCrop() async {
    if (state.cropProgress < 100.0) return false;

    // 1. Entregar puntos Dreams al usuario
    await _ref.read(userProvider.notifier).addPoints(state.rewardPoints);

    // 2. Definir siguiente cultivo y recompensa
    final nextLevel = state.level + 1;
    final totalH = state.totalHarvests + 1;
    String nextCrop;
    int nextReward;

    switch (totalH % 3) {
      case 1:
        nextCrop = 'Manzana Dreams';
        nextReward = 750;
        break;
      case 2:
        nextCrop = 'Trébol de la Suerte';
        nextReward = 1000;
        break;
      default:
        nextCrop = 'Trigo Dorado';
        nextReward = 500;
        break;
    }

    final updatedState = state.copyWith(
      cropProgress: 0.0,
      cropType: nextCrop,
      rewardPoints: nextReward,
      totalHarvests: totalH,
      level: nextLevel,
    );

    await _saveToFirestore(updatedState);
    return true;
  }
}
