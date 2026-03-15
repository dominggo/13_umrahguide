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
import '../data/umrah_data.dart';

class UmrahTamatScreen extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final List<JourneyPoint> gpsTrack;
  final List<CheckpointRecord> checkpoints;
  final String? journeyId; // non-null when viewing from history

  const UmrahTamatScreen({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.gpsTrack,
    required this.checkpoints,
    this.journeyId,
  });

  @override
  State<UmrahTamatScreen> createState() => _UmrahTamatScreenState();
}

class _UmrahTamatScreenState extends State<UmrahTamatScreen> {
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

  // ── Checkpoint helpers ────────────────────────────────────────────────────

  /// Scan umrahSteps to get the name for a checkpoint number.
  String _checkpointNameFor(int num) {
    for (final step in umrahSteps) {
      for (final sub in step.subSteps) {
        for (final doa in sub.duas) {
          if (doa.checkPointStart == num) {
            return doa.checkPointName ?? sub.title;
          }
        }
      }
    }
    return 'Checkpoint $num';
  }

  bool _canEdit() =>
      DateTime.now().difference(widget.endTime) <= const Duration(hours: 24);

  Future<void> _editCheckpoint(CheckpointRecord cp) async {
    final journeyId = widget.journeyId;
    if (journeyId == null) return;
    DateTime newStart = cp.startTime;
    DateTime? newEnd = cp.endTime;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Masa: ${cp.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Color(0xFF1B5E20)),
                title: const Text('Masa Mula'),
                subtitle: Text(_fmtFull(newStart)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: newStart,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null && ctx.mounted) {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(newStart),
                    );
                    if (t != null) {
                      setLocalState(() => newStart =
                          DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  }
                },
              ),
              if (newEnd != null)
                ListTile(
                  leading: const Icon(Icons.stop, color: Colors.red),
                  title: const Text('Masa Tamat'),
                  subtitle: Text(_fmtFull(newEnd!)),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: newEnd!,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null && ctx.mounted) {
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(newEnd!),
                      );
                      if (t != null) {
                        setLocalState(() => newEnd =
                            DateTime(d.year, d.month, d.day, t.hour, t.minute));
                      }
                    }
                  },
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await context.read<JourneyHistoryProvider>().updateCheckpoint(
                          journeyId,
                          cp.checkpointNum,
                          startTime: newStart,
                          endTime: newEnd,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtFull(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── Timeline builder ──────────────────────────────────────────────────────

  bool _isUmrahComplete(List<CheckpointRecord> cps) {
    final cpMap = {for (final c in cps) c.checkpointNum: c};
    for (int i = 1; i <= 17; i++) {
      if (cpMap[i]?.isCompleted != true) return false;
    }
    return true;
  }

  List<Widget> _buildCheckpointTimeline(List<CheckpointRecord> cps) {
    final cpMap = {for (final c in cps) c.checkpointNum: c};
    final canEdit = _canEdit();

    Widget cpOrSkip(int num) {
      final cp = cpMap[num];
      if (cp != null) {
        return _CheckpointTile(
          cp: cp,
          onEdit: canEdit ? () => _editCheckpoint(cp) : null,
        );
      }
      return _SkippedCheckpointTile(cpNum: num, name: _checkpointNameFor(num));
    }

    return [
      // CP1: individual (ihram)
      cpOrSkip(1),

      // CP2–8: Tawaf group (7 rounds)
      _CheckpointGroupTile(
        label: 'Tawaf (7 pusingan)',
        cpNums: const [2, 3, 4, 5, 6, 7, 8],
        cpMap: cpMap,
        checkpointNameFor: _checkpointNameFor,
        onEdit: canEdit ? _editCheckpoint : null,
      ),

      // CP9: individual (solat tawaf)
      cpOrSkip(9),

      // CP10–16: Saie group (7 entries)
      _CheckpointGroupTile(
        label: "Sa'ie (7 pusingan)",
        cpNums: const [10, 11, 12, 13, 14, 15, 16],
        cpMap: cpMap,
        checkpointNameFor: _checkpointNameFor,
        onEdit: canEdit ? _editCheckpoint : null,
      ),

      // CP17: individual (tahallul)
      cpOrSkip(17),
    ];
  }

  // ── Footer builder ────────────────────────────────────────────────────────

  Widget _buildFooter(List<CheckpointRecord> cps) {
    if (_isUmrahComplete(cps)) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: const Color(0xFF1B5E20),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.mosque, color: Colors.white, size: 36),
              SizedBox(height: 8),
              Text(
                'Alhamdulillah — Umrah Selesai',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Semoga diterima Allah s.w.t.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.amber[700],
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.warning_amber, color: Colors.white, size: 36),
            SizedBox(height: 8),
            Text(
              'Semak dan pastikan Umrah ini lengkap',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'Terdapat checkpoint yang belum selesai',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<JourneyHistoryProvider>();
    final umrahNum = history.totalUmrahCount;
    final hasGps = widget.gpsTrack.length > 1;

    // Use live checkpoints from provider when journeyId is available
    final checkpoints = widget.journeyId != null
        ? (history.getById(widget.journeyId!)?.checkpoints ?? widget.checkpoints)
        : widget.checkpoints;

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
                    interactionOptions:
                        InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      tileProvider: CachedTileProvider(
                        store: sharedTileCache,
                      ),
                      userAgentPackageName: 'com.example.umrah_guide',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.gpsTrack
                              .map((p) => LatLng(p.lat, p.lng))
                              .toList(),
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
                  const Text('Rekod Perjalanan',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (checkpoints.isEmpty)
                    const Text(
                      'Tiada rekod checkpoint.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    )
                  else
                    ..._buildCheckpointTimeline(checkpoints),
                ],
              ),
            ),

            // Footer (dynamic based on completion)
            _buildFooter(checkpoints),
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
      await Share.shareXFiles(
          [XFile(file.path)], text: 'Ringkasan Perjalanan Umrah saya');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal eksport: $e')));
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
                            style: pw.TextStyle(
                                font: boldFont,
                                color: PdfColors.white,
                                fontSize: 18)),
                        pw.Text('Ringkasan Perjalanan',
                            style: pw.TextStyle(
                                font: font,
                                color: PdfColor.fromHex('#CCFFFFFF'),
                                fontSize: 12)),
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
              pw.Text('Tempoh: ${_formatDuration(_duration)}',
                  style: pw.TextStyle(font: font)),
              pw.Text('Jarak: ${_distanceKm.toStringAsFixed(2)} km',
                  style: pw.TextStyle(font: font)),
              pw.SizedBox(height: 20),
              pw.Text('Rekod Checkpoint',
                  style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.SizedBox(height: 10),
              ...widget.checkpoints.map((cp) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 6),
                    child: pw.Row(
                      children: [
                        pw.Text('${cp.checkpointNum}. ',
                            style: pw.TextStyle(font: boldFont)),
                        pw.Text(cp.name, style: pw.TextStyle(font: font)),
                        pw.Spacer(),
                        pw.Text(
                          cp.isCompleted ? 'Selesai' : 'Tidak selesai',
                          style: pw.TextStyle(
                              font: font,
                              color: cp.isCompleted
                                  ? PdfColors.green900
                                  : PdfColors.orange),
                        ),
                      ],
                    ),
                  )),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.Text('Alhamdulillah — Umrah Selesai',
                    style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 16,
                        color: PdfColors.green900)),
              ),
            ],
          ),
        ),
      );

      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/umrah_summary.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Ringkasan PDF Perjalanan Umrah');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal eksport PDF: $e')));
      }
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Summary Header ───────────────────────────────────────────────────────────

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
            style: TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                  label: 'Tempoh',
                  value:
                      '${duration.inHours}j ${duration.inMinutes.remainder(60)}min'),
              const SizedBox(width: 12),
              _StatChip(
                  label: 'Jarak',
                  value: '${distanceKm.toStringAsFixed(2)} km'),
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
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Checkpoint Group Tile (collapsible) ──────────────────────────────────────

class _CheckpointGroupTile extends StatefulWidget {
  final String label;
  final List<int> cpNums;
  final Map<int, CheckpointRecord> cpMap;
  final String Function(int) checkpointNameFor;
  final void Function(CheckpointRecord)? onEdit;

  const _CheckpointGroupTile({
    required this.label,
    required this.cpNums,
    required this.cpMap,
    required this.checkpointNameFor,
    this.onEdit,
  });

  @override
  State<_CheckpointGroupTile> createState() => _CheckpointGroupTileState();
}

class _CheckpointGroupTileState extends State<_CheckpointGroupTile> {
  @override
  Widget build(BuildContext context) {
    final total = widget.cpNums.length;
    final startedCps = widget.cpNums
        .map((n) => widget.cpMap[n])
        .whereType<CheckpointRecord>()
        .toList();
    final completeCount =
        startedCps.where((c) => c.isCompleted).length;

    // Group colour: all complete = green, none started = red, partial = orange
    Color groupColor;
    if (startedCps.isEmpty) {
      groupColor = Colors.red[400]!;
    } else if (completeCount == total) {
      groupColor = const Color(0xFF1B5E20);
    } else {
      groupColor = Colors.orange;
    }

    // Collapsed subtitle: first start time — last end time
    final firstStart =
        startedCps.isEmpty ? null : startedCps.first.startTime;
    final lastEnd = startedCps.isEmpty
        ? null
        : startedCps
            .lastWhere((c) => c.endTime != null,
                orElse: () => startedCps.last)
            .endTime;
    String subtitle;
    if (firstStart != null) {
      final s =
          '${firstStart.hour.toString().padLeft(2, '0')}:${firstStart.minute.toString().padLeft(2, '0')}';
      final e = lastEnd != null
          ? '${lastEnd.hour.toString().padLeft(2, '0')}:${lastEnd.minute.toString().padLeft(2, '0')}'
          : '—';
      subtitle = '$s — $e';
    } else {
      subtitle = 'Tidak dimulakan';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: ExpansionTile(
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: groupColor,
            child: Text(
              '$completeCount/$total',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(widget.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          initiallyExpanded: false,
          children: widget.cpNums.map((cpN) {
            final cp = widget.cpMap[cpN];
            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: cp != null
                  ? _CheckpointTile(
                      cp: cp,
                      onEdit: widget.onEdit != null
                          ? () => widget.onEdit!(cp)
                          : null,
                    )
                  : _SkippedCheckpointTile(
                      cpNum: cpN,
                      name: widget.checkpointNameFor(cpN),
                    ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Individual Checkpoint Tile ───────────────────────────────────────────────

class _CheckpointTile extends StatelessWidget {
  final CheckpointRecord cp;
  final VoidCallback? onEdit;

  const _CheckpointTile({required this.cp, this.onEdit});

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
            backgroundColor:
                missed ? Colors.orange : const Color(0xFF1B5E20),
            child: Text(
              '${cp.checkpointNum}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
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
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Edit masa',
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ─── Skipped Checkpoint Tile ──────────────────────────────────────────────────

class _SkippedCheckpointTile extends StatelessWidget {
  final int cpNum;
  final String name;

  const _SkippedCheckpointTile({required this.cpNum, required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.red[400],
            child: const Icon(Icons.error_outline,
                color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.red[700])),
                const Text(
                  'Tidak dimulakan',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(Icons.error_outline, color: Colors.red[400], size: 16),
        ],
      ),
    );
  }
}
