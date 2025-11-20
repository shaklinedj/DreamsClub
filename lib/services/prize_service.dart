import 'dart:convert';
import 'package:casinoloyalty_flutter/models/won_prize_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrizeService {
  static const String _keyPrizes = 'won_prizes';

  /// Save a newly won prize
  Future<void> saveWonPrize(WonPrize prize) async {
    final prizes = await getMyPrizes();
    prizes.add(prize);
    await _savePrizes(prizes);
  }

  /// Get all user's prizes
  Future<List<WonPrize>> getMyPrizes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? prizesJson = prefs.getString(_keyPrizes);
    
    if (prizesJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(prizesJson);
    return decoded.map((json) => WonPrize.fromJson(json)).toList();
  }

  /// Get only active prizes (not redeemed, not expired)
  Future<List<WonPrize>> getActivePrizes() async {
    final allPrizes = await getMyPrizes();
    return allPrizes.where((prize) => prize.isActive).toList();
  }

  /// Get redeemed prizes (history)
  Future<List<WonPrize>> getRedeemedPrizes() async {
    final allPrizes = await getMyPrizes();
    return allPrizes.where((prize) => prize.redeemed).toList();
  }

  /// Redeem a prize (mark as used)
  Future<void> redeemPrize(String prizeId) async {
    final prizes = await getMyPrizes();
    final index = prizes.indexWhere((p) => p.id == prizeId);
    
    if (index != -1) {
      prizes[index] = prizes[index].copyWith(
        redeemed: true,
        redeemedAt: DateTime.now(),
      );
      await _savePrizes(prizes);
    }
  }

  /// Clear all prizes (for testing)
  Future<void> clearAllPrizes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrizes);
  }

  /// Internal: Save prizes list
  Future<void> _savePrizes(List<WonPrize> prizes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prizes.map((p) => p.toJson()).toList();
    await prefs.setString(_keyPrizes, jsonEncode(jsonList));
  }
}
