import 'package:casinoloyalty_flutter/models/feed_post_model.dart';

final List<FeedPost> mockFeedPosts = [
  FeedPost(
    id: 'mock1',
    title: 'Noche de Gala en Dreams Iquique',
    description:
        'Ven a disfrutar de una noche inolvidable con música en vivo y sorpresas.',
    mediaUrl:
        'https://images.unsplash.com/photo-1514525253361-bee1a275302b?auto=format&fit=crop&w=1200&q=80',
    mediaType: FeedMediaType.image,
    postType: FeedPostType.event,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likesCount: 150,
    commentsCount: 25,
    casinoId: '1',
  ),
  FeedPost(
    id: 'mock2',
    title: 'Sorteo Especial BMW X5',
    description:
        '¡Tus cupones de hoy podrían convertirte en el dueño de un BMW X5 cero kilómetros!',
    mediaUrl:
        'https://images.unsplash.com/photo-1555215695-3004980ad94e?auto=format&fit=crop&w=1200&q=80',
    mediaType: FeedMediaType.image,
    postType: FeedPostType.promotion,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    likesCount: 1200,
    commentsCount: 89,
    casinoId: '5',
  ),
  FeedPost(
    id: 'mock3',
    title: 'Nuevo Menú en Restaurante In',
    description:
        'Descubre los sabores de la Araucanía con nuestra nueva carta de temporada.',
    mediaUrl:
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
    mediaType: FeedMediaType.image,
    postType: FeedPostType.news,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    likesCount: 45,
    commentsCount: 12,
    casinoId: '2',
  ),
  FeedPost(
    id: 'mock4',
    title: 'Show de Luces en el Sky Bar',
    description:
        'La mejor vista de Valdivia acompañada de un espectáculo visual único.',
    mediaUrl:
        'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
    mediaType: FeedMediaType.image,
    postType: FeedPostType.event,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    likesCount: 88,
    commentsCount: 15,
    casinoId: '3',
  ),
];
