class AppwriteConfig {
  // Cambia esto por tu Endpoint real (ej: 'https://cloud.appwrite.io/v1' o tu IP)
  static const String endpoint = 'https://localhost/v1';

  // El ID de tu Proyecto en Appwrite
  static const String projectId = 'dreams-club-dev';

  // IDs de Base de Datos y Colecciones
  static const String databaseId = 'dreams_db';
  static const String collectionPosts = 'posts';
  static const String collectionComments = 'comments';
  static const String collectionUsers = 'users';

  // Storage Buckets
  static const String bucketImages = 'images';
  static const String bucketVideos = 'videos';
}
