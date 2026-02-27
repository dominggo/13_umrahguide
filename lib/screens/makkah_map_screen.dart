import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import '../utils/map_tile_cache.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/location_provider.dart';
import '../models/umrah_location.dart';
import '../models/umrah_step.dart';
import '../data/umrah_data.dart';
import 'doa_viewer_screen.dart';

const _makkahCenter = LatLng(21.4225, 39.8262);

class MakkahMapScreen extends StatefulWidget {
  const MakkahMapScreen({super.key});

  @override
  State<MakkahMapScreen> createState() => _MakkahMapScreenState();
}

class _MakkahMapScreenState extends State<MakkahMapScreen> {
  final MapController _mapCtrl = MapController();

  @override
  Widget build(BuildContext context) {
    final locProv = context.watch<LocationProvider>();
    final currentZone = locProv.currentZone;
    final pos = locProv.currentPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Masjidil Haram'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Lokasi Saya',
            onPressed: pos != null
                ? () => _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 18)
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            color: currentZone != null ? const Color(0xFF1B5E20) : Colors.grey[700],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  currentZone != null ? Icons.location_on : Icons.location_off,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentZone != null
                        ? 'Anda di: ${currentZone.nameMalay}'
                        : 'Di luar kawasan — pilih lokasi manual',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Map
          Expanded(
            child: FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: _makkahCenter,
                      initialZoom: 17,
                      minZoom: 14,
                      maxZoom: 19,
                      onLongPress: (tapPos, point) => _showManualZoneDialog(context, locProv),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        tileProvider: CachedTileProvider(
                          store: sharedTileCache,
                        ),
                        userAgentPackageName: 'com.example.umrah_guide',
                      ),
                      // GPS track (journey)
                      if (locProv.gpsTrack.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: locProv.gpsTrack
                                  .map((p) => LatLng(p.lat, p.lng))
                                  .toList(),
                              color: Colors.blue,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      // Zone markers
                      MarkerLayer(
                        markers: [
                          ...umrahLocations.map((loc) {
                            final isActive = currentZone?.id == loc.id;
                            return Marker(
                              point: loc.center,
                              width: 48,
                              height: 48,
                              child: GestureDetector(
                                onTap: () => _showZoneBottomSheet(context, loc),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xFF1B5E20)
                                        : const Color(0xFF388E3C).withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isActive ? 3 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: isActive ? 8 : 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.place, color: Colors.white, size: 24),
                                ),
                              ),
                            );
                          }),
                          // GPS blue dot
                          if (pos != null)
                            Marker(
                              point: LatLng(pos.latitude, pos.longitude),
                              width: 20,
                              height: 20,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.blue, blurRadius: 10)],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _mapCtrl.move(_makkahCenter, 17),
        backgroundColor: const Color(0xFF1B5E20),
        tooltip: 'Kembali ke Masjidil Haram',
        child: const Icon(Icons.home, color: Colors.white),
      ),
    );
  }

  void _showZoneBottomSheet(BuildContext context, UmrahLocation loc) {
    // Find related duas from umrahSteps
    final relatedDuas = <_DoaRef>[];
    for (final step in umrahSteps) {
      if (step.id == loc.stepId) {
        for (final sub in step.subSteps) {
          final duas = List<DoaItem>.from(sub.duas);
          for (int i = 0; i < duas.length; i++) {
            relatedDuas.add(_DoaRef(doa: duas[i], index: i, siblings: duas, substepTitle: sub.title));
          }
        }
        break;
      }
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Color(0xFF1B5E20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.nameMalay,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(loc.description, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (relatedDuas.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Doa berkaitan:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...relatedDuas.take(5).map((r) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.menu_book, color: Color(0xFF1B5E20), size: 20),
                    title: Text(r.doa.title, style: const TextStyle(fontSize: 13)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoaViewerScreen(
                            duas: r.siblings,
                            initialIndex: r.index,
                            title: r.substepTitle,
                          ),
                        ),
                      );
                    },
                  )),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showManualZoneDialog(BuildContext context, LocationProvider locProv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pilih Lokasi Semasa'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: umrahLocations.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              if (i == 0) {
                return ListTile(
                  leading: const Icon(Icons.gps_fixed),
                  title: const Text('Guna GPS automatik'),
                  onTap: () {
                    locProv.manualOverrideZone(null);
                    Navigator.pop(ctx);
                  },
                );
              }
              final loc = umrahLocations[i - 1];
              return ListTile(
                leading: const Icon(Icons.place, color: Color(0xFF1B5E20)),
                title: Text(loc.nameMalay, style: const TextStyle(fontSize: 13)),
                onTap: () {
                  locProv.manualOverrideZone(loc);
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DoaRef {
  final DoaItem doa;
  final int index;
  final List<DoaItem> siblings;
  final String substepTitle;
  const _DoaRef({required this.doa, required this.index, required this.siblings, required this.substepTitle});
}
