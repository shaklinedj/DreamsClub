import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/services/feed_media_cache_manager.dart';

class FeedMediaPrefetchService {
  FeedMediaPrefetchService._();

  static Future<void> prefetchPost(FeedPost post) async {
    final url = post.mediaUrl;

    if (url.isEmpty) return;

    // Prefetch using flutter_cache_manager

    try {
      // Downloads to device storage via flutter_cache_manager.
      await FeedMediaCacheManager.instance.downloadFile(url);
    } catch (_) {
      // Prefetch is best-effort.
    }
  }
}
