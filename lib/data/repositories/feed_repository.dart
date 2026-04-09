import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/models/comment_model.dart';

/// Interfaz que define las operaciones del Feed.
/// Permite cambiar entre Firebase y Appwrite sin romper la UI.
abstract class FeedRepository {
  /// Obtiene una lista de posts, opcionalmente filtrada por casino.
  Future<List<FeedPost>> getPosts({String? casinoId, int limit = 10});

  /// Crea un nuevo post.
  Future<void> createPost(FeedPost post);

  /// Borra un post por ID.
  Future<void> deletePost(String postId);

  /// Alterna el like en un post.
  Future<void> toggleLike(String postId, String userId);

  /// Añade un comentario a un post.
  Future<void> addComment(Comment comment);

  /// Escucha cambios en tiempo real (opcional, depende de la implementación).
  Stream<List<FeedPost>>? getFeedStream();
}
