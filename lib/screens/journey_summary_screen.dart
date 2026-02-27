import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:latlong2/latlong.dart';
import '../utils/map_tile_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import '../models/journey_models.dart';
import '../models/journey_history_provider.dart';
import '../models/journey_record.dart';
import '../models/progress_provider.dart';
import '../data/umrah_data.dart';

class JourneySummaryScreen extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final List<JourneyPoint> gpsTrack;
  final List<JourneyEvent> events;
  final String? journeyId; // non-null when viewing from history

  const JourneySummaryScreen({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.gpsTrack,
    required this.events,
    this.journeyId,
  });

  @override
  State<JourneySummaryScreen> createState() => _JourneySummaryScreenState();
}

class _JourneySummaryScreenState extends State<JourneySummaryScreen> {
  final _screenshotCtrl = ScreenshotController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSave());
  }

  Future<void> _autoSave() async {
    if (_saved || widget.journeyId != null) return;
    _saved = true;
    final history = context.read<JourneyHistoryProvider>();
    final prog = context.read<ProgressProvider>();
    final record = UmrahJourneyRecord(
      id: const Uuid().v4(),
      startTime: widget.startTime,
      endTime: widget.endTime,
      events: widget.events,
      gpsTrack: widget.gpsTrack,
    );
    await history.addJourney(record);
    await prog.clearProgress();
  }

  Duration get _duration => widget.endTime.difference(widget.startTime);

  double get _distanceKm {
    if (widget.gpsTrack.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < widget.gpsTrack.length; i++) {
      final p1 = widget.gpsTrack[i - 1];
      final p2 = widget.gpsTrack[i];
      total += _dist(p1.lat, p1.lng, p2.lat, p2.lng);
    }
    return total;
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = _sin2(dLat / 2) + _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLng / 2);
    return r * 2 * _asin(_sqrt(a));
  }

  double _rad(double d) => d * 3.14159265358979 / 180;
  double _sin2(double x) { final s = x - x*x*x/6 + x*x*x*x*x/120; return s * s; }
  double _cos(double x) => 1 - x*x/2 + x*x*x*x/24;
  double _asin(double x) => x + x*x*x/6;
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x;
    for (int i = 0; i < 10; i++) { g = (g + x / g) / 2; }
    return g;
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${h}j ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<JourneyHistoryProvider>();
    final umrahNum = history.totalUmrahCount;
    final hasGps = widget.gpsTrack.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Perjalanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Eksport PDF',
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Eksport PNG & Kongsi',
            onPressed: _exportPng,
          ),
        ],
      ),
      body: Screenshot(
        controller: _screenshotCtrl,
        child: ListView(
          children: [
            // Summary card header
            _SummaryHeader(
              umrahNum: umrahNum,
              startTime: widget.startTime,
              endTime: widget.endTime,
              duration: _duration,
              distanceKm: _distanceKm,
            ),

            // Map section
            if (hasGps)
              SizedBox(
                height: 220,
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(21.4225, 39.8262),
                    initialZoom: 17,
                    interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileProvider: CachedTileProvider(
                        store: sharedTileCache,
                      ),
                      userAgentPackageName: 'com.example.umrah_guide',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.gpsTrack.map((p) => LatLng(p.lat, p.lng)).toList(),
                          color: Colors.blue,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Step timeline
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rekod Langkah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...List.generate(umrahSteps.length, (i) {
                    final step = umrahSteps[i];
                    final stepEvents = widget.events.where((e) => e.stepId == step.id).toList();
                    final doaCount = stepEvents.where((e) => e.eventType == JourneyEventType.doaPlayed).length;
                    return _StepSummaryTile(
                      index: i + 1,
                      title: step.title,
                      doaCount: doaCount,
                      stepId: step.id,
                      events: widget.events,
                    );
                  }),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF1B5E20),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.mosque, color: Colors.white, size: 36),
                    SizedBox(height: 8),
                    Text(
                      'Alhamdulillah — Umrah Selesai',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Semoga diterima Allah s.w.t.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPng() async {
    try {
      final bytes = await _screenshotCtrl.capture();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/umrah_summary.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Ringkasan Perjalanan Umrah saya');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal eksport: $e')));
      }
    }
  }

  Future<void> _exportPdf() async {
    try {
      final doc = pw.Document();
      final font = await PdfGoogleFonts.nunitoRegular();
      final boldFont = await PdfGoogleFonts.nunitoBold();

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                color: PdfColors.green900,
                padding: const pw.EdgeInsets.all(20),
                child: pw.Row(
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Panduan Umrah', style: pw.TextStyle(font: boldFont, color: PdfColors.white, fontSize: 18)),
                        pw.Text('Ringkasan Perjalanan', style: pw.TextStyle(font: font, color: PdfColor.fromHex('#CCFFFFFF'), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Tarikh Mula: ${_formatDate(widget.startTime)}', style: pw.TextStyle(font: font)),
              pw.Text('Tarikh Tamat: ${_formatDate(widget.endTime)}', style: pw.TextStyle(font: font)),
              pw.Text('Tempoh: ${_formatDuration(_duration)}', style: pw.TextStyle(font: font)),
              pw.Text('Jarak: ${_distanceKm.toStringAsFixed(2)} km', style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              pw.Text('Rekod Langkah', style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.SizedBox(height: 10),
              ...List.generate(umrahSteps.length, (i) {
                final step = umrahSteps[i];
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    children: [
                      pw.Text('${i + 1}. ', style: pw.TextStyle(font: boldFont)),
                      pw.Text(step.title, style: pw.TextStyle(font: font)),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text('Alhamdulillah — Umrah Selesai', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.green900)),
              ),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/umrah_summary.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Ringkasan PDF Perjalanan Umrah');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal eksport PDF: $e')));
      }
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _SummaryHeader extends StatelessWidget {
  final int umrahNum;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double distanceKm;

  const _SummaryHeader({
    required this.umrahNum,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Umrah ke-$umrahNum',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Panduan Umrah',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(label: 'Tempoh', value: '${duration.inHours}j ${duration.inMinutes.remainder(60)}min'),
              const SizedBox(width: 12),
              _StatChip(label: 'Jarak', value: '${distanceKm.toStringAsFixed(2)} km'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mula: ${_fmt(startTime)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Tamat: ${_fmt(endTime)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StepSummaryTile extends StatelessWidget {
  final int index;
  final String title;
  final int doaCount;
  final String stepId;
  final List<JourneyEvent> events;

  const _StepSummaryTile({
    required this.index,
    required this.title,
    required this.doaCount,
    required this.stepId,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final stepEvent = events.where((e) => e.stepId == stepId && e.eventType == JourneyEventType.stepStart).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF1B5E20),
            child: Text('$index', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (stepEvent != null)
                  Text(
                    _fmt(stepEvent.timestamp),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (doaCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$doaCount doa', style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20))),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
