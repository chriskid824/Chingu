import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheManager {
  static const key = 'chingu_image_cache';

  static final ImageCacheManager _instance = ImageCacheManager._();

  factory ImageCacheManager() {
    return _instance;
  }

  ImageCacheManager._();

  final CacheManager _manager = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  CacheManager get manager => _manager;
}
