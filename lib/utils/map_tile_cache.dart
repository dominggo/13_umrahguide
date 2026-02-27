import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

/// Shared in-memory tile cache for all map screens.
/// Tiles are cached for the app session duration.
final MemCacheStore sharedTileCache = MemCacheStore();
