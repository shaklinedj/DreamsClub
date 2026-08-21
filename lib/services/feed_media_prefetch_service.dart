import 'package:casinoloyalty_flutter/models/feed_post_model.dart';
import 'package:casinoloyalty_flutter/services/feed_media_cache_manager.dart';

class FeedMediaPrefetchService {
  FeedMediaPrefetchService._();

  static String _formatUrl(String url, bool isVideo) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    String? fileId;
    if (trimmed.contains('drive.google.com/file/d/')) {
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('drive.google.com/open?id=')) {
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('drive.google.com/uc')) {
      final match = RegExp(r'id=([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    } else if (trimmed.contains('googleusercontent.com/d/')) {
      final match = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(trimmed);
      if (match != null) fileId = match.group(1);
    }

    if (fileId != null && fileId.isNotEmpty) {
      if (isVideo) {
        return 'https://drive.usercontent.google.com/download?id=$fileId&export=download';
      }
      return 'https://lh3.googleusercontent.com/d/$fileId';
    }
    return trimmed;
  }

  static Future<void> prefetchPost(FeedPost post) async {
    if (post.mediaUrl.contains('youtube.com') ||
        post.mediaUrl.contains('youtu.be')) {
      return; // Skip prefetching for YouTube videos
    }

    final isVideo = post.mediaType == FeedMediaType.video;
    final url = _formatUrl(post.mediaUrl, isVideo);

    if (url.isEmpty) return;

    try {
      await FeedMediaCacheManager.instance.downloadFile(url);
    } catch (_) {}
  }
}
