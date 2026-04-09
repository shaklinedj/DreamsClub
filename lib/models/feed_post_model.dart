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
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final ReactionType? reactionType; // Tipo de reacción del usuario actual
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
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.reactionType,
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
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    ReactionType? reactionType,
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
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      reactionType: clearReaction ? null : (reactionType ?? this.reactionType),
      casinoId: casinoId ?? this.casinoId,
      linkUrl: linkUrl ?? this.linkUrl,
    );
  }

  /// Check if user has any reaction
  bool get hasReaction => reactionType != null;

  /// Check if user has liked (for backward compatibility)
  bool get isLiked => reactionType != null;

  factory FeedPost.fromMap(Map<String, dynamic> map) {
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
      likesCount: (map['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (map['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (map['sharesCount'] as num?)?.toInt() ?? 0,
      reactionType: map['reactionType'] != null
          ? ReactionType.values.firstWhere(
              (e) => e.name == map['reactionType'],
              orElse: () => ReactionType.like,
            )
          : null,
      casinoId: map['casinoId']?.toString(),
      linkUrl: map['linkUrl']?.toString(),
    );
  }

  factory FeedPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return FeedPost.fromMap(data);
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
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'sharesCount': sharesCount,
      'reactionType': reactionType?.name,
      'casinoId': casinoId,
      'linkUrl': linkUrl,
    };
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
