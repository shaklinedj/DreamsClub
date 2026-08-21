import 'package:casinoloyalty_flutter/models/feed_post_model.dart';

final List<FeedPost> mockFeedPosts = [
  FeedPost(
    id: 'coyhaique_post_1',
    title: '¡Gran Noche de Ruleta & Música en Vivo!',
    description:
        'Ven a disfrutar del mejor ambiente de la Patagonia en Dreams Coyhaique. Coctelería de autor y sorpresas exclusivas para socios.',
    mediaUrl:
        'https://images.unsplash.com/photo-1514525253361-bee1a275302b?auto=format&fit=crop&w=1200&q=80',
    mediaType: FeedMediaType.image,
    postType: FeedPostType.event,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    reactionsCount: 84,
    commentsCount: 14,
    casinoId: '4',
    location: 'Dreams Coyhaique',
  ),
  FeedPost(
    id: 'coyhaique_post_2',
    title: 'Torneo Exclusivo de Poker Patagonia',
    description:
        'Inscripciones abiertas para el torneo mensual en Dreams Coyhaique. ¡Grandes premios para los mejores clasificados!',
    mediaUrl:
        'https://images.unsplash.com/photo-1511193311914-0346f16efe90?auto=format&fit=crop&w=1200&q=80',
    mediaType: FeedMediaType.image,
    postType: FeedPostType.promotion,
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    reactionsCount: 120,
    commentsCount: 22,
    casinoId: '4',
    location: 'Dreams Coyhaique',
  ),
  FeedPost(
    id: 'coyhaique_post_3',
    title: 'Nueva Carta Gastronómica Regional',
    description:
        'Sabores auténticos de Aysén en nuestro restaurante. Cordero patagónico, salmón y la mejor cava de vinos.',
    mediaUrl:
        'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1200&q=80',
    mediaType: FeedMediaType.image,
    postType: FeedPostType.news,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    reactionsCount: 65,
    commentsCount: 9,
    casinoId: '4',
    location: 'Dreams Coyhaique',
  ),
];

