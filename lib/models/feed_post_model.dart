import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_reactions/flutter_facebook_reactions.dart';

enum FeedPostType { event, promotion, news }

enum FeedMediaType { image, video }

class FeedPost {
  final String id;
  final String title;
  final String description;
  final String mediaUrl;
  final FeedMediaType mediaType;
  final FeedPostType postType;
  final DateTime createdAt;
  final String? location; // Para eventos
  final DateTime? eventDate; // Para eventos
  final int reactionsCount;
  final int commentsCount;
  final int sharesCount;
  final ReactionType? reactionType; // Tipo de reacción del usuario actual
  final Map<String, int> reactionCounts; // Desglose por tipo de reacción {'like': 2, 'love': 5}
  final Map<String, String> userReactions; // Mapa de usuario -> tipo {'userId1': 'love', 'userId2': 'like'}
  final String? casinoId;
  final String? linkUrl; // Link externo tipo Instagram

  const FeedPost({
    required this.id,
    required this.title,
    required this.description,
    required this.mediaUrl,
    required this.mediaType,
    required this.postType,
    required this.createdAt,
    this.location,
    this.eventDate,
    this.reactionsCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.reactionType,
    this.reactionCounts = const {},
    this.userReactions = const {},
    this.casinoId,
    this.linkUrl,
  });

  /// Create a copy with modified fields
  FeedPost copyWith({
    String? id,
    String? title,
    String? description,
    String? mediaUrl,
    FeedMediaType? mediaType,
    FeedPostType? postType,
    DateTime? createdAt,
    String? location,
    DateTime? eventDate,
    int? reactionsCount,
    int? commentsCount,
    int? sharesCount,
    ReactionType? reactionType,
    Map<String, int>? reactionCounts,
    Map<String, String>? userReactions,
    bool clearReaction = false,
    String? casinoId,
    String? linkUrl,
  }) {
    return FeedPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      postType: postType ?? this.postType,
      createdAt: createdAt ?? this.createdAt,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      reactionType: clearReaction ? null : (reactionType ?? this.reactionType),
      reactionCounts: reactionCounts ?? this.reactionCounts,
      userReactions: userReactions ?? this.userReactions,
      casinoId: casinoId ?? this.casinoId,
      linkUrl: linkUrl ?? this.linkUrl,
    );
  }

  /// Get top active reaction types for rendering stacked Facebook-style reaction badges
  List<ReactionType> get topReactions {
    if (reactionCounts.isNotEmpty) {
      final entries = reactionCounts.entries
          .where((e) => e.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (entries.isNotEmpty) {
        return entries.take(3).map((e) {
          return ReactionType.values.firstWhere(
            (r) => r.name == e.key,
            orElse: () => ReactionType.like,
          );
        }).toList();
      }
    }
    if (reactionType != null) {
      return [reactionType!];
    }
    return reactionsCount > 0 ? [ReactionType.like] : [];
  }

  /// Check if user has any reaction
  bool get hasReaction => reactionType != null;

  /// Check if user has liked (for backward compatibility)
  bool get isLiked => reactionType != null;

  factory FeedPost.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    Map<String, String> userReactionsMap = {};
    if (map['userReactions'] is Map) {
      (map['userReactions'] as Map).forEach((k, v) {
        userReactionsMap[k.toString()] = v.toString();
      });
    }

    int computedReactionsCount = (map['reactionsCount'] as num?)?.toInt() ?? userReactionsMap.length;
    Map<String, int> computedReactionCounts = {};
    if (map['reactionCounts'] is Map) {
      (map['reactionCounts'] as Map).forEach((k, v) {
        computedReactionCounts[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }

    ReactionType? currentUserReaction;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      final cleanId = currentUserId.replaceAll('.', '_').replaceAll('@', '_');
      if (userReactionsMap.containsKey(currentUserId)) {
        currentUserReaction = parseReactionType(userReactionsMap[currentUserId]);
      } else if (userReactionsMap.containsKey(cleanId)) {
        currentUserReaction = parseReactionType(userReactionsMap[cleanId]);
      }
    } else {
      currentUserReaction = parseReactionType(map['reactionType']);
    }

    return FeedPost(
      id: map['id'] ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      mediaUrl: map['mediaUrl']?.toString() ?? '',
      mediaType: _parseMediaType(map['mediaType']),
      postType: _parsePostType(map['postType']),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now(),
      location: map['location']?.toString(),
      eventDate: map['eventDate'] is Timestamp
          ? (map['eventDate'] as Timestamp).toDate()
          : (map['eventDate'] != null
              ? DateTime.tryParse(map['eventDate'].toString())
              : null),
      reactionsCount: computedReactionsCount,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (map['sharesCount'] as num?)?.toInt() ?? 0,
      reactionType: currentUserReaction,
      reactionCounts: computedReactionCounts,
      userReactions: userReactionsMap,
      casinoId: map['casinoId']?.toString(),
      linkUrl: map['linkUrl']?.toString(),
    );
  }

  factory FeedPost.fromFirestore(DocumentSnapshot doc, {String? currentUserId}) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return FeedPost.fromMap(data, currentUserId: currentUserId);
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.toString().split('.').last,
      'postType': postType.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'location': location,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'reactionsCount': reactionsCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'reactionType': reactionType?.name,
      'reactionCounts': reactionCounts,
      'userReactions': userReactions,
      'casinoId': casinoId,
      'linkUrl': linkUrl,
    };
  }

  factory FeedPost.fromJsonMap(Map<String, dynamic> map, {String? currentUserId}) {
    return FeedPost.fromMap(map, currentUserId: currentUserId);
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType.toString().split('.').last,
      'postType': postType.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'location': location,
      'eventDate': eventDate?.toIso8601String(),
      'reactionsCount': reactionsCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'reactionType': reactionType?.name,
      'reactionCounts': reactionCounts,
      'casinoId': casinoId,
      'linkUrl': linkUrl,
    };
  }

  static ReactionType? parseReactionType(dynamic value) {
    if (value == null) return null;
    final str = value.toString().split('.').last.trim().toLowerCase();
    for (final type in ReactionType.values) {
      if (type.name.toLowerCase() == str) {
        return type;
      }
    }
    return null;
  }

  static FeedMediaType _parseMediaType(dynamic value) {
    if (value == null) return FeedMediaType.image;
    return FeedMediaType.values.firstWhere(
      (e) => e.toString().split('.').last == value.toString().split('.').last,
      orElse: () => FeedMediaType.image,
    );
  }

  static FeedPostType _parsePostType(dynamic value) {
    if (value == null) return FeedPostType.news;
    return FeedPostType.values.firstWhere(
      (e) => e.toString().split('.').last == value.toString().split('.').last,
      orElse: () => FeedPostType.news,
    );
  }
}
