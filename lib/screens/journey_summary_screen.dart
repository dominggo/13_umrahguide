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
import '../models/journey_models.dart';
import '../models/journey_history_provider.dart';
import '../models/progress_provider.dart';

class JourneySummaryScreen extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final List<JourneyPoint> gpsTrack;
  final List<CheckpointRecord> checkpoints;
  final String? journeyId; // non-null when viewing from history

  const JourneySummaryScreen({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.gpsTrack,
    required this.checkpoints,
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
    if (_saved) return;
    _saved = true;
    final prog = context.read<ProgressProvider>();
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

            // Checkpoint timeline
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rekod Perjalanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (widget.checkpoints.isEmpty)
                    const Text(
                      'Tiada rekod checkpoint.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    )
                  else
                    ...widget.checkpoints.map((cp) => _CheckpointTile(cp: cp)),
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
                        pw.Text('Panduan Umrah',
                            style: pw.TextStyle(font: boldFont, color: PdfColors.white, fontSize: 18)),
                        pw.Text('Ringkasan Perjalanan',
                            style: pw.TextStyle(
                                font: font, color: PdfColor.fromHex('#CCFFFFFF'), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Tarikh Mula: ${_formatDate(widget.startTime)}',
                  style: pw.TextStyle(font: font)),
              pw.Text('Tarikh Tamat: ${_formatDate(widget.endTime)}',
                  style: pw.TextStyle(font: font)),
              pw.Text('Tempoh: ${_formatDuration(_duration)}', style: pw.TextStyle(font: font)),
              pw.Text('Jarak: ${_distanceKm.toStringAsFixed(2)} km',
                  style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              pw.Text('Rekod Checkpoint', style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.SizedBox(height: 10),
              ...widget.checkpoints.map((cp) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      children: [
                        pw.Text('${cp.checkpointNum}. ', style: pw.TextStyle(font: boldFont)),
                        pw.Text(cp.name, style: pw.TextStyle(font: font)),
                        pw.Spacer(),
                        pw.Text(
                          cp.isCompleted ? 'Selesai' : 'Tidak selesai',
                          style: pw.TextStyle(
                              font: font,
                              color: cp.isCompleted ? PdfColors.green900 : PdfColors.orange),
                        ),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text('Alhamdulillah — Umrah Selesai',
                    style: pw.TextStyle(
                        font: boldFont, fontSize: 16, color: PdfColors.green900)),
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
              _StatChip(
                  label: 'Tempoh',
                  value: '${duration.inHours}j ${duration.inMinutes.remainder(60)}min'),
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
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CheckpointTile extends StatelessWidget {
  final CheckpointRecord cp;

  const _CheckpointTile({required this.cp});

  @override
  Widget build(BuildContext context) {
    final missed = !cp.isCompleted;
    final startFmt = _fmt(cp.startTime);
    final endFmt = cp.endTime != null ? _fmt(cp.endTime!) : null;
    final dur = cp.endTime?.difference(cp.startTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: missed ? Colors.orange : const Color(0xFF1B5E20),
            child: Text(
              '${cp.checkpointNum}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cp.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: missed ? Colors.orange[800] : null)),
                Text(
                  missed
                      ? 'Mula: $startFmt — Tidak Diselesaikan'
                      : 'Mula: $startFmt — Tamat: ${endFmt ?? '-'}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (dur != null)
                  Text(
                    'Tempoh: ${dur.inMinutes}min',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          if (missed)
            const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
