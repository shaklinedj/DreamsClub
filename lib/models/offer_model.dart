import 'package:flutter/material.dart';

class Offer {
  final int id;
  final String title;
  final String type;
  final IconData icon;
  final String validity;
  final int pointsCost;
  final int casinoId; // Added to filter by casino

  Offer({
    required this.id,
    required this.title,
    required this.type,
    required this.icon,
    required this.validity,
    required this.pointsCost,
    required this.casinoId,
  });
}
