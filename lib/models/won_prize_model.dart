import 'package:casinoloyalty_flutter/models/prize_model.dart';

class WonPrize {
  final String id;
  final Prize prize;
  final DateTime wonAt;
  final int casinoId;
  final String qrCode;
  final bool redeemed;
  final DateTime? redeemedAt;

  WonPrize({
    required this.id,
    required this.prize,
    required this.wonAt,
    required this.casinoId,
    required this.qrCode,
    this.redeemed = false,
    this.redeemedAt,
  });

  DateTime get expiresAt => wonAt.add(Duration(days: prize.daysValid));
  
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  bool get isActive => !redeemed && !isExpired;

  String get daysUntilExpiry {
    if (isExpired) return 'Expirado';
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} días';
    if (diff.inHours > 0) return '${diff.inHours} horas';
    return '${diff.inMinutes} minutos';
  }

  factory WonPrize.fromJson(Map<String, dynamic> json) {
    return WonPrize(
      id: json['id'],
      prize: Prize.fromJson(json['prize']),
      wonAt: DateTime.parse(json['wonAt']),
      casinoId: json['casinoId'],
      qrCode: json['qrCode'],
      redeemed: json['redeemed'] ?? false,
      redeemedAt: json['redeemedAt'] != null
          ? DateTime.parse(json['redeemedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prize': prize.toJson(),
      'wonAt': wonAt.toIso8601String(),
      'casinoId': casinoId,
      'qrCode': qrCode,
      'redeemed': redeemed,
      'redeemedAt': redeemedAt?.toIso8601String(),
    };
  }

  WonPrize copyWith({
    bool? redeemed,
    DateTime? redeemedAt,
  }) {
    return WonPrize(
      id: id,
      prize: prize,
      wonAt: wonAt,
      casinoId: casinoId,
      qrCode: qrCode,
      redeemed: redeemed ?? this.redeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
    );
  }
}
