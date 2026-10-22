import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';
import '../models/journey_models.dart';
import 'geo.dart';

/// Shared OSM tile cache for all map screens. On disk (after [initTileCache]),
/// so tiles seen once while online are still shown offline in Makkah.
CacheStore sharedTileCache = MemCacheStore();

/// Call once before runApp; falls back to the in-memory store on error.
Future<void> initTileCache() async {
  try {
    final dir = await getApplicationSupportDirectory();
    sharedTileCache = FileCacheStore('${dir.path}/map_tiles');
  } catch (e) {
    debugPrint('Tile cache init failed, using memory: $e');
  }
}

/// Recorded track: walked stretches solid blue, GPS gaps dashed grey.
PolylineLayer trackLayer(List<JourneyPoint> track) {
  final seg = trackSegments(track);
  return PolylineLayer(
    polylines: [
      for (final g in seg.gaps)
        Polyline(
          points: g,
          color: Colors.grey,
          strokeWidth: 2,
          // ignore: prefer_const_constructors (its assert can't run in const)
          pattern: StrokePattern.dashed(segments: const [6, 6]),
        ),
      for (final w in seg.walked)
        Polyline(points: w, color: Colors.blue, strokeWidth: 3),
    ],
  );
}

/// OSM tile layer with the shared cache and the app's user agent (required
/// by the OSM tile usage policy).
TileLayer osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.faeq.umrahmas',
      tileProvider: CachedTileProvider(
        store: sharedTileCache,
        maxStale: const Duration(days: 365),
      ),
    );
