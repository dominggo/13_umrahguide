import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/location_provider.dart';
import '../models/umrah_location.dart';
import '../models/umrah_step.dart';
import '../data/umrah_data.dart';
import '../utils/format.dart';
import '../utils/map_tile_cache.dart';
import 'doa_viewer_screen.dart';

const _makkahCenter = LatLng(21.4225, 39.8262);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapCtrl = MapController();

  @override
  Widget build(BuildContext context) {
    // Rebuilds on zone/journey changes; the GPS dot and track listen to
    // locProv.position separately.
    final locProv = context.watch<LocationProvider>();
    final currentZone = locProv.currentZone;

    // Title is in HomeScreen's AppBar.
    return Scaffold(
      body: Column(
        children: [
          // Status bar
          Container(
            color: currentZone != null ? kPrimaryGreen : Colors.grey[700],
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
                        : 'Di luar kawasan — tekan lama peta untuk pilih lokasi',
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
                onLongPress: (tapPos, point) =>
                    _showManualZoneDialog(context, locProv),
              ),
              children: [
                osmTileLayer(),
                // Zone polygons (behind markers)
                PolygonLayer(
                  polygons: umrahLocations
                      .where((l) => l.polygon != null && l.polygon!.isNotEmpty)
                      .map((loc) {
                    final isActive = currentZone?.id == loc.id;
                    return Polygon(
                      points: loc.polygon!,
                      color: isActive
                          ? kPrimaryGreen.withValues(alpha: 0.2)
                          : const Color(0xFF388E3C).withValues(alpha: 0.15),
                      borderColor: isActive ? kPrimaryGreen : Colors.green,
                      borderStrokeWidth: isActive ? 2 : 1,
                    );
                  }).toList(),
                ),
                // Zone markers (for circle-based zones or just centers)
                MarkerLayer(
                  markers: [
                    for (final loc
                        in umrahLocations.where((l) => l.center != null))
                      _zoneMarker(loc, currentZone?.id == loc.id),
                  ],
                ),
                // GPS track (journey) and blue dot, updated on every fix
                ValueListenableBuilder<Position?>(
                  valueListenable: locProv.position,
                  builder: (_, __, ___) =>
                      locProv.isJourneyActive && locProv.gpsTrack.length > 1
                          ? trackLayer(locProv.gpsTrack)
                          : const SizedBox.shrink(),
                ),
                ValueListenableBuilder<Position?>(
                  valueListenable: locProv.position,
                  builder: (_, pos, __) => pos == null
                      ? const SizedBox.shrink()
                      : MarkerLayer(markers: [
                          Marker(
                            point: LatLng(pos.latitude, pos.longitude),
                            width: 20,
                            height: 20,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Colors.blue, blurRadius: 10)
                                ],
                              ),
                            ),
                          ),
                        ]),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<Position?>(
            valueListenable: locProv.position,
            builder: (_, pos, __) => FloatingActionButton.small(
              heroTag: 'map_my_location',
              onPressed: pos != null
                  ? () =>
                      _mapCtrl.move(LatLng(pos.latitude, pos.longitude), 18)
                  : null,
              backgroundColor: pos != null ? kPrimaryGreen : Colors.grey,
              tooltip: 'Lokasi Saya',
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'map_home',
            onPressed: () => _mapCtrl.move(_makkahCenter, 17),
            backgroundColor: kPrimaryGreen,
            tooltip: 'Kembali ke Masjidil Haram',
            child: const Icon(Icons.home, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Marker _zoneMarker(UmrahLocation loc, bool isActive) => Marker(
        point: loc.center!,
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _showZoneBottomSheet(context, loc),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              color: isActive
                  ? kPrimaryGreen
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

  void _showZoneBottomSheet(BuildContext context, UmrahLocation loc) {
    // Find related duas from umrahSteps
    final relatedDuas = <_DoaRef>[];
    for (final step in umrahSteps) {
      if (step.id == loc.stepId) {
        for (final sub in step.subSteps) {
          // Only include duas from the specific substep if specified
          if (loc.substepId != null && sub.id != loc.substepId) {
            continue;
          }
          for (int i = 0; i < sub.duas.length; i++) {
            relatedDuas.add(_DoaRef(
                doa: sub.duas[i],
                index: i,
                siblings: sub.duas,
                substepTitle: sub.title,
                stepId: step.id,
                substepId: sub.id));
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
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: kPrimaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.nameMalay,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(loc.description,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (relatedDuas.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Doa berkaitan:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...relatedDuas.take(5).map((r) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.menu_book,
                        color: kPrimaryGreen, size: 20),
                    title:
                        Text(r.doa.title, style: const TextStyle(fontSize: 13)),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoaViewerScreen(
                            duas: r.siblings,
                            initialIndex: r.index,
                            title: r.substepTitle,
                            stepId: r.stepId,
                            substepId: r.substepId,
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
                leading: const Icon(Icons.place, color: kPrimaryGreen),
                title:
                    Text(loc.nameMalay, style: const TextStyle(fontSize: 13)),
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
  final String stepId;
  final String substepId;
  const _DoaRef({
    required this.doa,
    required this.index,
    required this.siblings,
    required this.substepTitle,
    required this.stepId,
    required this.substepId,
  });
}
