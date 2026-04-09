// ignore_for_file: deprecated_member_use

import 'package:appwrite/appwrite.dart';
import 'package:casinoloyalty_flutter/data/repositories/feed_repository.dart';
import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/models/comment_model.dart';
import 'package:casinoloyalty_flutter/services/appwrite/appwrite_config.dart';
import 'package:casinoloyalty_flutter/services/appwrite/appwrite_service.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AppwriteFeedRepository implements FeedRepository {
  final Databases _databases;

  AppwriteFeedRepository({AppwriteService? service})
      : _databases = (service ?? AppwriteService()).databases;

  @override
  Future<List<FeedPost>> getPosts({String? casinoId, int limit = 10}) async {
    try {
      final queries = [
        Query.orderDesc('createdAt'),
        Query.limit(limit),
      ];

      if (casinoId != null && casinoId.isNotEmpty) {
        queries.add(Query.equal('casinoId', casinoId));
      }

      final result = await _databases.listDocuments(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.collectionPosts,
        queries: queries,
      );

      return result.documents.map((doc) {
        // Por ahora usamos un mapeo manual temporal
        final data = doc.data;
        data['id'] = doc.$id; // El ID en Appwrite es $id
        // Adaptación temporal para compatibilidad con el formato de Firestore
        return FeedPost.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error obteniendo posts de Appwrite: $e');
      return [];
    }
  }

  @override
  Future<void> createPost(FeedPost post) async {
    try {
      await _databases.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.collectionPosts,
        documentId: ID.unique(),
        data: post.toMap()..remove('id'), // Dejamos que Appwrite genere el ID
      );
    } catch (e) {
      debugPrint('Error creando post en Appwrite: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    await _databases.deleteDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.collectionPosts,
      documentId: postId,
    );
  }

  @override
  Future<void> toggleLike(String postId, String userId) async {
    // Implementación optimista simplificada
    // En Appwrite, necesitarías leer el documento primero para ver array de likes
    // O usar una Appwrite Function para lógica atómica del lado del servidor.
    try {
      await _databases.getDocument(
          databaseId: AppwriteConfig.databaseId,
          collectionId: AppwriteConfig.collectionPosts,
          documentId: postId);

      // Asumiendo que guardas likes como array de strings en 'likedBy'
      // Nota: Appwrite no tiene array-contains nativo tan simple como Firestore para updates atómicos
      // Se recomienda usar relaciones o lógica en Backend Functions.
      // Aquí mostramos lógica cliente (menos segura ante concurrencia):
      /*
        List<dynamic> likedBy = doc.data['likedBy'] ?? [];
        if (likedBy.contains(userId)) {
            likedBy.remove(userId);
        } else {
            likedBy.add(userId);
        }
        
        await _databases.updateDocument(
            databaseId: AppwriteConfig.databaseId,
            collectionId: AppwriteConfig.collectionPosts,
            documentId: postId,
            data: {'likedBy': likedBy}
        );
        */
    } catch (e) {
      debugPrint('Error toggleLike Appwrite: $e');
    }
  }

  @override
  Future<void> addComment(Comment comment) async {
    // Appwrite no tiene subcolecciones anidadas como Firestore
    // Guardamos en colección 'comments' con referencia 'postId'
    await _databases.createDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: AppwriteConfig.collectionComments,
      documentId: ID.unique(),
      data: comment.toMap(),
    );
  }

  @override
  Stream<List<FeedPost>>? getFeedStream() {
    // Implementación de Realtime
    // Retorna null por ahora, requiere mapear eventos de Appwrite Subscription a Lista
    return null;
  }
}
