import 'package:flutter/material.dart';

/// Facebook-style reaction types
enum ReactionType {
  like,
  love,
  haha,
  wow,
  sad,
  angry,
}

extension ReactionTypeExtension on ReactionType {
  /// Get the emoji representation
  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.haha:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
    }
  }

  /// Get the color associated with this reaction (Facebook-style)
  Color get color {
    switch (this) {
      case ReactionType.like:
        return const Color(0xFF1877F2); // Facebook blue
      case ReactionType.love:
        return const Color(0xFFF33E58); // Red/pink
      case ReactionType.haha:
        return const Color(0xFFF7B125); // Yellow/gold
      case ReactionType.wow:
        return const Color(0xFFF7B125); // Yellow/gold
      case ReactionType.sad:
        return const Color(0xFFF7B125); // Yellow/gold
      case ReactionType.angry:
        return const Color(0xFFE9710F); // Orange
    }
  }

  /// Get the label for this reaction
  String get label {
    switch (this) {
      case ReactionType.like:
        return 'Me gusta';
      case ReactionType.love:
        return 'Me encanta';
      case ReactionType.haha:
        return 'Me divierte';
      case ReactionType.wow:
        return 'Me asombra';
      case ReactionType.sad:
        return 'Me entristece';
      case ReactionType.angry:
        return 'Me enoja';
    }
  }

  /// Get animation scale factor for this reaction
  double get animationScale {
    switch (this) {
      case ReactionType.like:
        return 1.2;
      case ReactionType.love:
        return 1.3;
      case ReactionType.haha:
        return 1.25;
      case ReactionType.wow:
        return 1.3;
      case ReactionType.sad:
        return 1.2;
      case ReactionType.angry:
        return 1.25;
    }
  }
}
