import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_facebook_reactions/flutter_facebook_reactions.dart';
import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/models/comment_model.dart'; // Add Comment import
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:firebase_core/firebase_core.dart';

class FeedNotifier extends StateNotifier<List<FeedPost>> {
  FeedNotifier() : super([]) {
    // init
    _init();
  }

  void _init() {
    // Attempt to load from Firebase
    Future.microtask(() async {
      try {
        await loadPosts();
      } catch (e, stack) {
        AppLogger.error('Error in FeedNotifier initial load', e, stack);
      }
    });
  }

  CollectionReference get _postsCollection =>
      FirebaseFirestore.instance.collection('posts');

  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _currentCasinoId;

  Future<void> loadPosts({String? casinoId, bool isRefresh = true}) async {
    // If casinoId is provided, update our current target
    if (casinoId != null) {
      // If switching casinos, force refresh
      if (_currentCasinoId != casinoId) {
        _currentCasinoId = casinoId;
        isRefresh = true;
      }
    }

    if (isRefresh) {
      _lastDocument = null;
      _hasMore = true;
      // If refresh is requested but no specific casino is passed, we keep using the current one
      // If we want to reset to "all", user must pass empty string or handled elsewhere
      // But typically we want to keep filtering by the context we are in.

      // Note: If casinoId is passed as explicit null, we might want to clear filter?
      // For now, let's assume if loadPosts is called without args, it means "load more of current".
      // If called WITH args, it sets the scope.
    }

    if (!_hasMore || _isLoadingMore) return;

    // Use current scoped casinoId
    final targetCasinoId = _currentCasinoId;

    _isLoadingMore = true;

    _isLoadingMore = true;
    try {
      if (Firebase.apps.isEmpty) {
        AppLogger.warning('Firebase not initialized. Feed empty.');
        _hasMore = false;
        return;
      }

      Query baseQuery = _postsCollection.orderBy('createdAt', descending: true);
      Query queryToExecute = baseQuery;
      bool isFiltered = false;

      if (targetCasinoId != null && targetCasinoId.isNotEmpty) {
        queryToExecute = _postsCollection
            .where('casinoId', isEqualTo: targetCasinoId)
            .orderBy('createdAt', descending: true);
        isFiltered = true;
      }

      if (_lastDocument != null) {
        queryToExecute = queryToExecute.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot;
      String? requestedCasinoId =
          targetCasinoId; // Store for local filtering (use target, not arg)
      try {
        snapshot = await queryToExecute.limit(10).get();
      } catch (e) {
        if (isFiltered) {
          // Fallback for missing index - load all and filter locally
          AppLogger.warning(
              'Filtering locally due to missing index for casinoId: $targetCasinoId');
          if (_lastDocument != null) {
            baseQuery = baseQuery.startAfterDocument(_lastDocument!);
          }
          snapshot = await baseQuery.limit(50).get(); // Get more to filter
        } else {
          rethrow;
        }
      }

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        _isLoadingMore = false;
        if (isRefresh) state = [];
        return;
      }

      _lastDocument = snapshot.docs.last;

      var newPosts = snapshot.docs.map((doc) {
        return FeedPost.fromFirestore(doc);
      }).toList();

      // Apply local filter if we had to fallback
      if (isFiltered &&
          requestedCasinoId != null &&
          requestedCasinoId.isNotEmpty) {
        newPosts = newPosts
            .where((post) => post.casinoId == requestedCasinoId)
            .toList();
      }

      if (isRefresh) {
        state = newPosts;
      } else {
        state = [...state, ...newPosts];
      }

      _hasMore = snapshot.docs.length == 10;
    } catch (e, stack) {
      AppLogger.error('Error loading posts from Firestore', e, stack);
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> addPost(FeedPost post) async {
    try {
      if (Firebase.apps.isEmpty) return;

      final docRef = _postsCollection.doc();
      final postWithId = post.copyWith(id: docRef.id);

      await docRef.set(postWithId.toMap());

      state = [postWithId, ...state];
    } catch (e, stack) {
      AppLogger.error('Error creating post', e, stack);
      rethrow;
    }
  }

  void setReaction(String postId, ReactionType? reaction) {
    state = [
      for (final post in state)
        if (post.id == postId) _updateReaction(post, reaction) else post,
    ];

    _syncReactionToFirestore(postId, reaction);
  }

  Future<void> _syncReactionToFirestore(
      String postId, ReactionType? reaction) async {
    try {
      if (Firebase.apps.isEmpty) return;

      final docRef = _postsCollection.doc(postId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final currentLikes = (snapshot.data() as Map)['likesCount'] ?? 0;
        final serverReactionStr =
            (snapshot.data() as Map)['reactionType'] as String?;
        final serverHadReaction = serverReactionStr != null;
        final newHasReaction = reaction != null;

        int newLikesCount = currentLikes;
        if (!serverHadReaction && newHasReaction) {
          newLikesCount = currentLikes + 1;
        } else if (serverHadReaction && !newHasReaction) {
          newLikesCount = (currentLikes - 1).clamp(0, 999999);
        }

        transaction.update(docRef, {
          'reactionType': reaction?.name,
          'likesCount': newLikesCount,
        });
      });
    } catch (e, stack) {
      AppLogger.error('Error syncing reaction to Firestore', e, stack);
    }
  }

  FeedPost _updateReaction(FeedPost post, ReactionType? newReaction) {
    final hadReaction = post.reactionType != null;
    final hasNewReaction = newReaction != null;

    int likesChange = 0;
    if (!hadReaction && hasNewReaction) {
      likesChange = 1;
    } else if (hadReaction && !hasNewReaction) {
      likesChange = -1;
    }

    return post.copyWith(
      reactionType: newReaction,
      clearReaction: newReaction == null,
      likesCount: post.likesCount + likesChange,
    );
  }

  void toggleLike(String postId) {
    final post = state.firstWhere((p) => p.id == postId);
    if (post.reactionType != null) {
      setReaction(postId, null);
    } else {
      setReaction(postId, ReactionType.like);
    }
  }

  // --- COMMENTS ---

  Future<void> addComment(String postId, String text, String userId,
      String userName, String? userAvatar,
      {String collectionPath = 'posts',
      String? replyToUserName,
      String? parentId}) async {
    try {
      if (Firebase.apps.isEmpty) return;

      final collectionRef =
          FirebaseFirestore.instance.collection(collectionPath);
      final commentsRef = collectionRef.doc(postId).collection('comments');

      final newComment = Comment(
        id: '', // Auto-id
        postId: postId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        text: text,
        createdAt: DateTime.now(),
        replyToUserName: replyToUserName,
        parentId: parentId,
      );

      // Transaction to add comment AND update post count
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postRef = collectionRef.doc(postId);
        final postSnap = await transaction.get(postRef);

        if (!postSnap.exists) {
          // If parent doesn't exist (e.g. event from different source?), we might fail or create dummy?
          // For now, allow failing if strictly consistent, OR create if missing?
          // Let's assume it exists. If not, throw.
          throw Exception('Entity $postId not found in $collectionPath');
        }

        // Add comment doc
        final newCommentRef = commentsRef.doc();
        transaction.set(newCommentRef, newComment.toMap());

        // Increment count
        final currentComments = (postSnap.data() as Map)['commentsCount'] ?? 0;
        transaction.update(postRef, {'commentsCount': currentComments + 1});
      });

      // Update local state ONLY if it's the 'posts' collection (Main Feed)
      if (collectionPath == 'posts') {
        state = [
          for (final post in state)
            if (post.id == postId)
              post.copyWith(commentsCount: post.commentsCount + 1)
            else
              post,
        ];
      }
    } catch (e, stack) {
      AppLogger.error('Error adding comment', e, stack);
      rethrow;
    }
  }

  Future<void> toggleCommentLike(String postId, String commentId, String userId,
      {String collectionPath = 'posts'}) async {
    try {
      if (Firebase.apps.isEmpty) return;

      final commentRef = FirebaseFirestore.instance
          .collection(collectionPath)
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(commentRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        int likesCount = data['likesCount'] ?? 0;

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          likesCount = (likesCount - 1).clamp(0, 999999);
        } else {
          likedBy.add(userId);
          likesCount++;
        }

        transaction.update(commentRef, {
          'likedBy': likedBy,
          'likesCount': likesCount,
        });
      });
    } catch (e, stack) {
      AppLogger.error('Error toggling comment like', e, stack);
    }
  }

  // --- SHARES ---

  Future<void> incrementShare(String postId) async {
    try {
      if (Firebase.apps.isEmpty) return;

      // Fire and forget update
      await _postsCollection.doc(postId).update({
        'sharesCount': FieldValue.increment(1),
      });

      // Update local
      state = [
        for (final post in state)
          if (post.id == postId)
            post.copyWith(sharesCount: post.sharesCount + 1)
          else
            post,
      ];
    } catch (e, stack) {
      AppLogger.error('Error incrementing share', e, stack);
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      if (Firebase.apps.isEmpty) {
        state = state.where((post) => post.id != postId).toList();
        return;
      }
      await _postsCollection.doc(postId).delete();
      state = state.where((post) => post.id != postId).toList();
    } catch (e, stack) {
      AppLogger.error('Error deleting post', e, stack);
      rethrow;
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, List<FeedPost>>((ref) {
  return FeedNotifier();
});
