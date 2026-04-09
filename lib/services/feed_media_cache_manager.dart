import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:casinoloyalty_flutter/core/constants/app_constants.dart';

class FeedMediaCacheManager extends CacheManager {
  static const String cacheKey = 'feedMediaCache';

  static final FeedMediaCacheManager instance = FeedMediaCacheManager._();

  FeedMediaCacheManager._()
      : super(
          Config(
            cacheKey,
            stalePeriod: AppConstants.cacheMaxAge,
            maxNrOfCacheObjects: 200,
          ),
        );
}
