import 'package:casinoloyalty_flutter/models/prize_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WonPrize {
  final String id;
  final Prize prize;
  final String redemptionCode;
  final DateTime wonAt;
  final DateTime expiresAt;
  final String casinoId;
  final String qrCode;
  final String status; // 'disponible', 'cobrado', 'expirado'
  final String gameSource;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRut;
  final bool redeemed;
  final DateTime? redeemedAt;
  final String? redeemedBy;

  WonPrize({
    required this.id,
    required this.prize,
    required this.redemptionCode,
    required this.wonAt,
    DateTime? expiresAt,
    required this.casinoId,
    required this.qrCode,
    this.status = 'disponible',
    this.gameSource = 'roulette',
    this.userId = '',
    this.userName = '',
    this.userEmail = '',
    this.userRut = '',
    this.redeemed = false,
    this.redeemedAt,
    this.redeemedBy,
  }) : expiresAt = expiresAt ?? wonAt.add(Duration(days: prize.daysValid));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isRedeemed => redeemed || status == 'cobrado';

  bool get isActive => !isRedeemed && !isExpired;

  String get effectiveStatus {
    if (isRedeemed) return 'cobrado';
    if (isExpired) return 'expirado';
    return 'disponible';
  }

  String get daysUntilExpiry {
    if (isExpired) return 'Expirado';
    final diff = expiresAt.difference(DateTime.now());
    if (diff.inDays > 0) return '${diff.inDays} días';
    if (diff.inHours > 0) return '${diff.inHours} horas';
    return '${diff.inMinutes} minutos';
  }

  factory WonPrize.fromJson(Map<String, dynamic> json) {
    final prizeMap = json['prize'] is Map<String, dynamic>
        ? json['prize'] as Map<String, dynamic>
        : <String, dynamic>{
            'id': json['prizeId'] ?? 'custom_prize',
            'name': json['prizeName'] ?? 'Premio Dreams',
            'type': json['prizeType'] ?? 'drink',
            'icon': json['prizeIcon'] ?? '🎁',
            'description': json['prizeDescription'] ?? '',
          };

    final wonAt = (json['wonAt'] is String)
        ? DateTime.tryParse(json['wonAt']) ?? DateTime.now()
        : (json['wonAt'] is Timestamp
            ? (json['wonAt'] as Timestamp).toDate()
            : DateTime.now());

    final expiresAt = (json['expiresAt'] is String)
        ? DateTime.tryParse(json['expiresAt'])
        : (json['expiresAt'] is Timestamp
            ? (json['expiresAt'] as Timestamp).toDate()
            : null);

    final redeemedVal = json['redeemed'] == true || json['status'] == 'cobrado';

    return WonPrize(
      id: json['id']?.toString() ?? '',
      prize: Prize.fromJson(prizeMap),
      redemptionCode: json['redemptionCode']?.toString() ??
          json['code']?.toString() ??
          json['qrCode']?.toString() ??
          '',
      wonAt: wonAt,
      expiresAt: expiresAt,
      casinoId: json['casinoId']?.toString() ?? '4',
      qrCode: json['qrCode']?.toString() ??
          json['redemptionCode']?.toString() ??
          '',
      status: json['status']?.toString() ?? (redeemedVal ? 'cobrado' : 'disponible'),
      gameSource: json['gameSource']?.toString() ?? 'roulette',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      userEmail: json['userEmail']?.toString() ?? '',
      userRut: json['userRut']?.toString() ?? '',
      redeemed: redeemedVal,
      redeemedAt: json['redeemedAt'] != null
          ? (json['redeemedAt'] is String
              ? DateTime.tryParse(json['redeemedAt'])
              : (json['redeemedAt'] is Timestamp
                  ? (json['redeemedAt'] as Timestamp).toDate()
                  : null))
          : null,
      redeemedBy: json['redeemedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prize': prize.toJson(),
      'prizeId': prize.id,
      'prizeName': prize.name,
      'prizeType': prize.type.name,
      'prizeIcon': prize.icon,
      'prizeDescription': prize.description,
      'redemptionCode': redemptionCode,
      'wonAt': wonAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'casinoId': casinoId,
      'qrCode': qrCode,
      'status': effectiveStatus,
      'gameSource': gameSource,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRut': userRut,
      'redeemed': isRedeemed,
      'redeemedAt': redeemedAt?.toIso8601String(),
      'redeemedBy': redeemedBy,
    };
  }

  WonPrize copyWith({
    bool? redeemed,
    String? status,
    DateTime? redeemedAt,
    String? redeemedBy,
  }) {
    return WonPrize(
      id: id,
      prize: prize,
      redemptionCode: redemptionCode,
      wonAt: wonAt,
      expiresAt: expiresAt,
      casinoId: casinoId,
      qrCode: qrCode,
      status: status ?? this.status,
      gameSource: gameSource,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userRut: userRut,
      redeemed: redeemed ?? this.redeemed,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      redeemedBy: redeemedBy ?? this.redeemedBy,
    );
  }
}
