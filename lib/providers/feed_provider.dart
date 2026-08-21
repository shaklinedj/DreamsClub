import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_facebook_reactions/flutter_facebook_reactions.dart';
import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/models/comment_model.dart';
import 'package:casinoloyalty_flutter/models/user_model.dart';
import 'package:casinoloyalty_flutter/providers/auth_provider.dart';
import 'package:casinoloyalty_flutter/providers/user_provider.dart';
import 'package:casinoloyalty_flutter/core/utils/app_logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';

class FeedNotifier extends StateNotifier<List<FeedPost>> {
  final Map<String, ReactionType> _userReactions = {};
  List<FeedPost> _rawPosts = [];
  String _currentUserId = '';
  String? _currentCasinoId;
  bool _hasLoaded = false;

  /// True cuando el primer snapshot de Firestore ya llegó (cargando vs vacío real).
  bool get hasLoaded => _hasLoaded;

  StreamSubscription? _postsSubscription;
  StreamSubscription? _userReactionsSubscription;

  FeedNotifier() : super([]) {
    _currentUserId = fb_auth.FirebaseAuth.instance.currentUser?.uid ??
        fb_auth.FirebaseAuth.instance.currentUser?.email ??
        '';
    _init();
  }

  CollectionReference get _postsCollection =>
      FirebaseFirestore.instance.collection('posts');

  String _cleanKey(String id) => id.replaceAll('.', '_').replaceAll('@', '_');

  void _init() {
    _loadCachedPosts().then((_) {
      _listenToFirestorePosts();
      if (_currentUserId.isNotEmpty) {
        _listenToUserReactions(_currentUserId);
      }
    });
  }

  Future<void> _loadCachedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString('cached_feed_posts');
      if (cachedString != null && cachedString.isNotEmpty) {
        final decoded = jsonDecode(cachedString) as List;
        final cachedPosts = decoded.map((item) => FeedPost.fromJsonMap(Map<String, dynamic>.from(item))).toList();
        if (cachedPosts.isNotEmpty) {
          _rawPosts = cachedPosts;
          _hasLoaded = true;
          _applyReactionsToState();
        }
      }
    } catch (e) {
      AppLogger.error('Error loading cached feed posts', e);
    }
  }

  Future<void> _savePostsToCache(List<FeedPost> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(posts.map((p) => p.toJsonMap()).toList());
      await prefs.setString('cached_feed_posts', encoded);
    } catch (e) {
      AppLogger.error('Error saving feed posts to cache', e);
    }
  }

  void updateCurrentUser(String userId) {
    if (userId.isEmpty || userId == _currentUserId) return;
    _currentUserId = userId;
    _listenToUserReactions(userId);
  }

  Future<void> loadPosts({String? casinoId, bool isRefresh = true}) async {
    _currentCasinoId = casinoId;
    _listenToFirestorePosts();
  }

  /// 1. Escuchar publicaciones generales en tiempo real
  void _listenToFirestorePosts() {
    try {
      if (Firebase.apps.isEmpty) return;

      _postsSubscription?.cancel();

      Query query = _postsCollection.orderBy('createdAt', descending: true);
      if (_currentCasinoId != null && _currentCasinoId!.isNotEmpty) {
        // Si se desea filtrar por casino
        query = query.where('casinoId', isEqualTo: _currentCasinoId);
      }

      _postsSubscription = query.snapshots().listen((snapshot) {
        _hasLoaded = true;
        if (snapshot.docs.isNotEmpty) {
          _rawPosts = snapshot.docs.map((doc) {
            return FeedPost.fromFirestore(doc, currentUserId: _currentUserId);
          }).toList();
          _applyReactionsToState();
          _savePostsToCache(_rawPosts);
        } else if (!snapshot.metadata.isFromCache) {
          _rawPosts = [];
          state = [];
          _savePostsToCache(_rawPosts);
        }
      }, onError: (e) {
        _hasLoaded = true;
        AppLogger.error('Error listening to feed posts', e);
      });
    } catch (e) {
      AppLogger.error('Firestore feed init error', e);
    }
  }

  /// 2. Escuchar todas las reacciones del usuario actual mediante Collection Group Query
  void _listenToUserReactions(String userId) {
    try {
      if (Firebase.apps.isEmpty || userId.isEmpty) return;

      _userReactionsSubscription?.cancel();
      _userReactionsSubscription = FirebaseFirestore.instance
          .collectionGroup('reactions')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        _userReactions.clear();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final postId = data['postId'] as String? ?? doc.reference.parent.parent?.id;
          final type = FeedPost.parseReactionType(data['reactionType']);
          if (postId != null && postId.isNotEmpty && type != null) {
            _userReactions[postId] = type;
          }
        }
        _applyReactionsToState();
      }, onError: (e) {
        AppLogger.error('Error listening to collectionGroup reactions', e);
      });
    } catch (e) {
      AppLogger.error('CollectionGroup listener init error', e);
    }
  }

  /// Fusiona las publicaciones con las reacciones reales del usuario
  void _applyReactionsToState() {
    if (_rawPosts.isEmpty) {
      state = [];
      return;
    }

    state = _rawPosts.map((post) {
      final myReaction = _userReactions[post.id] ?? post.reactionType;
      return post.copyWith(
        reactionType: myReaction,
        clearReaction: myReaction == null,
      );
    }).toList();
  }

  // --- CREAR PUBLICACIÓN ---

  Future<void> addPost(FeedPost post) async {
    try {
      if (Firebase.apps.isEmpty) return;
      final docRef = _postsCollection.doc();
      final postData = post.toMap();
      await docRef.set(postData);
    } catch (e, stack) {
      AppLogger.error('Error adding post', e, stack);
      rethrow;
    }
  }

  // --- ACCIONES DE REACCIÓN (ARQUITECTURA DE SUBCOLECCIÓN ÚNICA) ---

  Future<void> setReaction(String postId, ReactionType? newReaction,
      {String? userId, String? userName}) async {
    try {
      final effectiveUserId = (userId != null && userId.isNotEmpty)
          ? userId
          : (_currentUserId.isNotEmpty
              ? _currentUserId
              : fb_auth.FirebaseAuth.instance.currentUser?.uid ?? '');

      if (effectiveUserId.isEmpty) return;

      final postIndex = _rawPosts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) return;

      final currentPost = _rawPosts[postIndex];
      final oldReaction = _userReactions[postId] ?? currentPost.reactionType;

      // Si se toca exactamente la misma reacción, se desactiva (toggle off)
      final targetReaction =
          (newReaction != null && oldReaction == newReaction) ? null : newReaction;

      // 1. Actualización Optimista Local (0 milisegundos de latencia)
      if (targetReaction != null) {
        _userReactions[postId] = targetReaction;
      } else {
        _userReactions.remove(postId);
      }

      final Map<String, int> updatedCounts =
          Map<String, int>.from(currentPost.reactionCounts);

      if (oldReaction != null) {
        final prev = updatedCounts[oldReaction.name] ?? 0;
        if (prev <= 1) {
          updatedCounts.remove(oldReaction.name);
        } else {
          updatedCounts[oldReaction.name] = prev - 1;
        }
      }

      if (targetReaction != null) {
        final cur = updatedCounts[targetReaction.name] ?? 0;
        updatedCounts[targetReaction.name] = cur + 1;
      }

      int countDiff = 0;
      if (oldReaction == null && targetReaction != null) countDiff = 1;
      if (oldReaction != null && targetReaction == null) countDiff = -1;

      final newTotal = (currentPost.reactionsCount + countDiff).clamp(0, 999999);

      final updatedPost = currentPost.copyWith(
        reactionType: targetReaction,
        clearReaction: targetReaction == null,
        reactionCounts: updatedCounts,
        reactionsCount: newTotal,
      );

      _rawPosts = [
        for (int i = 0; i < _rawPosts.length; i++)
          if (i == postIndex) updatedPost else _rawPosts[i],
      ];

      _applyReactionsToState();

      // 2. Sincronización en la Nube (Firestore Subcollections + Atomic Counters)
      if (Firebase.apps.isEmpty) return;

      final postDocRef = _postsCollection.doc(postId);
      final reactionDocRef = postDocRef.collection('reactions').doc(effectiveUserId);
      final cleanUserId = _cleanKey(effectiveUserId);

      if (targetReaction != null) {
        // A. Guardar/Sobrescribir documento único en la subcolección
        await reactionDocRef.set({
          'userId': effectiveUserId,
          'userName': userName ?? 'Usuario',
          'reactionType': targetReaction.name,
          'postId': postId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // B. Actualizar contadores agregados en el documento del post
        final Map<String, dynamic> postUpdates = {
          'userReactions.$cleanUserId': targetReaction.name,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (oldReaction == null) {
          postUpdates['reactionsCount'] = FieldValue.increment(1);
          postUpdates['reactionCounts.${targetReaction.name}'] = FieldValue.increment(1);
        } else if (oldReaction != targetReaction) {
          postUpdates['reactionCounts.${oldReaction.name}'] = FieldValue.increment(-1);
          postUpdates['reactionCounts.${targetReaction.name}'] = FieldValue.increment(1);
        }

        await postDocRef.set(postUpdates, SetOptions(merge: true));
      } else {
        // A. Eliminar documento de la subcolección
        await reactionDocRef.delete();

        // B. Decrementar contadores en el documento del post
        final Map<String, dynamic> postUpdates = {
          'userReactions.$cleanUserId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (oldReaction != null) {
          postUpdates['reactionsCount'] = FieldValue.increment(-1);
          postUpdates['reactionCounts.${oldReaction.name}'] = FieldValue.increment(-1);
        }

        await postDocRef.set(postUpdates, SetOptions(merge: true));
      }
    } catch (e, stack) {
      AppLogger.error('Error setting reaction in Firestore subcollection', e, stack);
    }
  }

  void toggleLike(String postId, {String? userId, String? userName}) {
    final currentReaction = _userReactions[postId];
    if (currentReaction != null) {
      setReaction(postId, null, userId: userId, userName: userName);
    } else {
      setReaction(postId, ReactionType.like,
          userId: userId, userName: userName);
    }
  }

  // --- COMENTARIOS ---

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
        id: '',
        postId: postId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        text: text,
        createdAt: DateTime.now(),
        replyToUserName: replyToUserName,
        parentId: parentId,
      );

      final newCommentDoc = commentsRef.doc();
      await newCommentDoc.set(newComment.toMap());

      final postRef = collectionRef.doc(postId);
      await postRef.set({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, stack) {
      AppLogger.error('Error adding comment', e, stack);
      rethrow;
    }
  }

  Future<void> deleteComment(String postId, String commentId,
      {String collectionPath = 'posts'}) async {
    try {
      if (Firebase.apps.isEmpty) return;

      final collectionRef =
          FirebaseFirestore.instance.collection(collectionPath);

      await collectionRef
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();

      final postRef = collectionRef.doc(postId);
      await postRef.set({
        'commentsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, stack) {
      AppLogger.error('Error deleting comment', e, stack);
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

  // --- SHARES & POST ACTIONS ---

  Future<void> incrementShare(String postId) async {
    try {
      if (Firebase.apps.isEmpty) return;

      await _postsCollection.doc(postId).update({
        'sharesCount': FieldValue.increment(1),
      });
    } catch (e, stack) {
      AppLogger.error('Error incrementing share', e, stack);
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      if (Firebase.apps.isEmpty) {
        _rawPosts = _rawPosts.where((post) => post.id != postId).toList();
        state = state.where((post) => post.id != postId).toList();
        return;
      }
      await _postsCollection.doc(postId).delete();
      _rawPosts = _rawPosts.where((post) => post.id != postId).toList();
      state = state.where((post) => post.id != postId).toList();
    } catch (e, stack) {
      AppLogger.error('Error deleting post', e, stack);
      rethrow;
    }
  }

  @override
  void dispose() {
    _postsSubscription?.cancel();
    _userReactionsSubscription?.cancel();
    super.dispose();
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, List<FeedPost>>((ref) {
  final notifier = FeedNotifier();

  // Escuchar cambios de usuario/autenticación para mantener el stream sincronizado
  ref.listen<User?>(userProvider, (previous, next) {
    final authUid = ref.read(authProvider).firebaseUser?.uid;
    final id = (authUid != null && authUid.isNotEmpty)
        ? authUid
        : (next != null && next.email.isNotEmpty ? next.email : (next?.name ?? ''));
    if (id.isNotEmpty) {
      notifier.updateCurrentUser(id);
    }
  });

  // Identificación inicial
  final authUid = ref.read(authProvider).firebaseUser?.uid;
  final user = ref.read(userProvider);
  final initialId = (authUid != null && authUid.isNotEmpty)
      ? authUid
      : (user.email.isNotEmpty ? user.email : user.name);

  if (initialId.isNotEmpty) {
    notifier.updateCurrentUser(initialId);
  }

  return notifier;
});
