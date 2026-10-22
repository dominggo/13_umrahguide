import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/journey_models.dart';
import '../models/journey_history_provider.dart';
import '../data/umrah_data.dart';
import '../utils/format.dart';
import '../utils/geo.dart';
import '../utils/map_tile_cache.dart';

class UmrahTamatScreen extends StatefulWidget {
  final DateTime startTime;
  final DateTime endTime;
  final List<JourneyPoint> gpsTrack;
  final List<CheckpointRecord> checkpoints;
  final String? journeyId; // non-null when viewing from history
  final JourneyKind kind;

  const UmrahTamatScreen({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.gpsTrack,
    required this.checkpoints,
    this.journeyId,
    this.kind = JourneyKind.umrah,
  });

  @override
  State<UmrahTamatScreen> createState() => _UmrahTamatScreenState();
}

class _UmrahTamatScreenState extends State<UmrahTamatScreen> {
  final _screenshotCtrl = ScreenshotController();
  late final double _distanceKm = trackDistanceKm(widget.gpsTrack);
  bool _exporting = false;

  Duration get _duration => widget.endTime.difference(widget.startTime);

  bool get _isWida => widget.kind == JourneyKind.wida;

  /// Short name of this kind of session, for titles and share text.
  String get _kindLabel => _isWida ? "Tawaf Wida'" : 'Umrah';

  /// Checkpoints from history when available, so edits show immediately.
  List<CheckpointRecord> _liveCheckpoints(JourneyHistoryProvider history) =>
      widget.journeyId != null
          ? (history.getById(widget.journeyId!)?.checkpoints ??
              widget.checkpoints)
          : widget.checkpoints;

  int _ordinal(JourneyHistoryProvider history) {
    // Number of this record among journeys of its kind (not the latest count)
    final n =
        widget.journeyId != null ? history.ordinalOf(widget.journeyId!) : 0;
    if (n > 0) return n;
    return _isWida ? history.totalWidaCount : history.totalUmrahCount;
  }

  bool _canEdit() =>
      widget.journeyId != null &&
      DateTime.now().difference(widget.endTime) <= const Duration(hours: 24);

  Future<void> _editCheckpoint(CheckpointRecord cp) async {
    final journeyId = widget.journeyId;
    if (journeyId == null) return;
    DateTime newStart = cp.startTime;
    DateTime? newEnd = cp.endTime;

    Future<DateTime?> pick(BuildContext ctx, DateTime initial) async {
      final d = await showDatePicker(
        context: ctx,
        initialDate: initial,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      );
      if (d == null || !ctx.mounted) return null;
      final t = await showTimePicker(
        context: ctx,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (t == null) return null;
      return DateTime(d.year, d.month, d.day, t.hour, t.minute);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) {
          final valid = newEnd == null || newEnd!.isAfter(newStart);
          return Padding(
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.play_arrow, color: kPrimaryGreen),
                  title: const Text('Masa Mula'),
                  subtitle: Text(fmtDateTime(newStart)),
                  onTap: () async {
                    final v = await pick(ctx, newStart);
                    if (v != null) setLocalState(() => newStart = v);
                  },
                ),
                if (newEnd != null)
                  ListTile(
                    leading: const Icon(Icons.stop, color: Colors.red),
                    title: const Text('Masa Tamat'),
                    subtitle: Text(fmtDateTime(newEnd!)),
                    onTap: () async {
                      final v = await pick(ctx, newEnd!);
                      if (v != null) setLocalState(() => newEnd = v);
                    },
                  ),
                if (!valid)
                  Text('Masa tamat mesti selepas masa mula.',
                      style: TextStyle(color: Colors.red[700], fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: !valid
                        ? null
                        : () async {
                            await context
                                .read<JourneyHistoryProvider>()
                                .updateCheckpoint(
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<JourneyHistoryProvider>();
    final checkpoints = _liveCheckpoints(history);
    final hasGps = widget.gpsTrack.length > 1;
    final trackPoints =
        widget.gpsTrack.map((p) => LatLng(p.lat, p.lng)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Perjalanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Eksport PDF',
            onPressed: _exporting ? null : () => _exportPdf(checkpoints),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Eksport PNG & Kongsi',
            onPressed: _exporting ? null : () => _exportPng(history),
          ),
        ],
      ),
      body: ListView(
        children: [
          _SummaryHeader(
            kind: widget.kind,
            ordinal: _ordinal(history),
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
                options: MapOptions(
                  initialCameraFit: CameraFit.coordinates(
                    coordinates: trackPoints,
                    padding: const EdgeInsets.all(24),
                    maxZoom: 18,
                  ),
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  osmTileLayer(),
                  trackLayer(widget.gpsTrack),
                ],
              ),
            ),

          _SummaryBody(
            kind: widget.kind,
            checkpoints: checkpoints,
            onEdit: _canEdit() ? _editCheckpoint : null,
          ),
        ],
      ),
    );
  }

  /// Captures the whole summary (not just the visible part of the list).
  /// The map is left out: tiles don't load in an off-screen capture.
  Future<void> _exportPng(JourneyHistoryProvider history) async {
    setState(() => _exporting = true);
    try {
      final summary = Material(
        color: Colors.white,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryHeader(
                kind: widget.kind,
                ordinal: _ordinal(history),
                startTime: widget.startTime,
                endTime: widget.endTime,
                duration: _duration,
                distanceKm: _distanceKm,
              ),
              _SummaryBody(
                kind: widget.kind,
                checkpoints: _liveCheckpoints(history),
                expandGroups: true,
              ),
            ],
          ),
        ),
      );
      final bytes = await _screenshotCtrl.captureFromLongWidget(
        summary,
        context: context,
        pixelRatio: 2,
        delay: const Duration(milliseconds: 100),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/umrah_summary.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Ringkasan Perjalanan $_kindLabel saya');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal eksport: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf(List<CheckpointRecord> checkpoints) async {
    setState(() => _exporting = true);
    try {
      // Bundled fonts: export must work offline.
      final font =
          pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Regular.ttf'));
      final boldFont =
          pw.Font.ttf(await rootBundle.load('assets/fonts/Nunito-Bold.ttf'));
      final cpMap = {for (final c in checkpoints) c.checkpointNum: c};
      final complete = _isComplete(widget.kind, checkpoints);

      final doc = pw.Document(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
      );
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Container(
              color: PdfColors.green900,
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Panduan Umrah',
                      style: pw.TextStyle(
                          font: boldFont,
                          color: PdfColors.white,
                          fontSize: 18)),
                  pw.Text('Ringkasan Perjalanan $_kindLabel',
                      style: pw.TextStyle(
                          color: PdfColor.fromHex('#CCFFFFFF'),
                          fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Tarikh Mula: ${fmtDateTime(widget.startTime)}'),
            pw.Text('Tarikh Tamat: ${fmtDateTime(widget.endTime)}'),
            pw.Text('Tempoh: ${fmtDuration(_duration)}'),
            pw.Text('Jarak: ${_distanceKm.toStringAsFixed(2)} km'),
            pw.SizedBox(height: 20),
            pw.Text('Rekod Checkpoint',
                style: pw.TextStyle(font: boldFont, fontSize: 14)),
            pw.SizedBox(height: 10),
            for (int n = widget.kind.firstCp; n <= widget.kind.lastCp; n++)
              _pdfCheckpointRow(n, cpMap[n], boldFont),
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text(
                  complete
                      ? 'Alhamdulillah — $_kindLabel Selesai'
                      : 'Terdapat checkpoint yang belum selesai',
                  style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: complete
                          ? PdfColors.green900
                          : PdfColors.orange800)),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/umrah_summary.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Ringkasan PDF Perjalanan $_kindLabel');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal eksport PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Widget _pdfCheckpointRow(int n, CheckpointRecord? cp, pw.Font boldFont) {
    final (String status, PdfColor color) = cp == null
        ? ('Tidak dimulakan', PdfColors.red700)
        : cp.isCompleted
            ? ('Selesai ${fmtTime(cp.startTime)}–${fmtTime(cp.endTime!)}',
                PdfColors.green900)
            : ('Tidak selesai (mula ${fmtTime(cp.startTime)})',
                PdfColors.orange800);
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
              width: 24,
              child: pw.Text('$n.', style: pw.TextStyle(font: boldFont))),
          pw.Expanded(child: pw.Text(cp?.name ?? checkpointName(n))),
          pw.Text(status, style: pw.TextStyle(color: color)),
        ],
      ),
    );
  }
}

bool _isComplete(JourneyKind kind, List<CheckpointRecord> cps) {
  final cpMap = {for (final c in cps) c.checkpointNum: c};
  for (int i = kind.firstCp; i <= kind.lastCp; i++) {
    if (cpMap[i]?.isCompleted != true) return false;
  }
  return true;
}

// ─── Summary body (timeline + footer) ─────────────────────────────────────────

/// Checkpoint timeline and completion footer. Shared by the screen and the
/// PNG export ([expandGroups] shows every round without tapping).
class _SummaryBody extends StatelessWidget {
  final JourneyKind kind;
  final List<CheckpointRecord> checkpoints;
  final void Function(CheckpointRecord)? onEdit;
  final bool expandGroups;

  const _SummaryBody({
    required this.kind,
    required this.checkpoints,
    this.onEdit,
    this.expandGroups = false,
  });

  bool get _isWida => kind == JourneyKind.wida;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rekod Perjalanan',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (checkpoints.isEmpty)
                const Text(
                  'Tiada rekod checkpoint.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                )
              else
                ..._timeline(),
            ],
          ),
        ),
        _footer(),
      ],
    );
  }

  List<Widget> _timeline() {
    final cpMap = {for (final c in checkpoints) c.checkpointNum: c};

    Widget cpOrSkip(int num) {
      final cp = cpMap[num];
      if (cp != null) {
        return _CheckpointTile(
          cp: cp,
          onEdit: onEdit != null ? () => onEdit!(cp) : null,
        );
      }
      return _SkippedCheckpointTile(cpNum: num, name: checkpointName(num));
    }

    Widget group(String label, List<int> nums) => _CheckpointGroupTile(
          label: label,
          cpNums: nums,
          cpMap: cpMap,
          onEdit: onEdit,
          expanded: expandGroups,
        );

    if (_isWida) {
      // CP18–24: Tawaf Wida' (7 rounds)
      return [group("Tawaf Wida' (7 pusingan)", const [18, 19, 20, 21, 22, 23, 24])];
    }

    return [
      cpOrSkip(1), // ihram
      group('Tawaf (7 pusingan)', const [2, 3, 4, 5, 6, 7, 8]),
      cpOrSkip(9), // solat tawaf
      group("Sa'ie (7 pusingan)", const [10, 11, 12, 13, 14, 15, 16]),
      cpOrSkip(17), // tahallul
    ];
  }

  Widget _footer() {
    final kindLabel = _isWida ? "Tawaf Wida'" : 'Umrah';
    if (_isComplete(kind, checkpoints)) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: kPrimaryGreen,
        child: Column(
          children: [
            const Icon(Icons.mosque, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(
              'Alhamdulillah — $kindLabel Selesai',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Semoga diterima Allah s.w.t.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.amber[700],
      child: Column(
        children: [
          const Icon(Icons.warning_amber, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(
            'Semak dan pastikan $kindLabel ini lengkap',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Terdapat checkpoint yang belum selesai',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Header ───────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  final JourneyKind kind;
  final int ordinal;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double distanceKm;

  const _SummaryHeader({
    required this.kind,
    required this.ordinal,
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
          colors: [kPrimaryGreen, Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kind == JourneyKind.wida
                ? "Tawaf Wida' ke-$ordinal"
                : 'Umrah ke-$ordinal',
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
              _StatChip(label: 'Tempoh', value: fmtDuration(duration)),
              const SizedBox(width: 12),
              _StatChip(
                  label: 'Jarak', value: '${distanceKm.toStringAsFixed(2)} km'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mula: ${fmtDateTime(startTime)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            'Tamat: ${fmtDateTime(endTime)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
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

class _CheckpointGroupTile extends StatelessWidget {
  final String label;
  final List<int> cpNums;
  final Map<int, CheckpointRecord> cpMap;
  final void Function(CheckpointRecord)? onEdit;

  /// Show the rounds as a plain list instead of a collapsed ExpansionTile.
  final bool expanded;

  const _CheckpointGroupTile({
    required this.label,
    required this.cpNums,
    required this.cpMap,
    this.onEdit,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = cpNums.length;
    final startedCps =
        cpNums.map((n) => cpMap[n]).whereType<CheckpointRecord>().toList();
    final completeCount = startedCps.where((c) => c.isCompleted).length;

    // Group colour: all complete = green, none started = red, partial = orange
    final Color groupColor = startedCps.isEmpty
        ? Colors.red[400]!
        : completeCount == total
            ? kPrimaryGreen
            : Colors.orange;

    // Collapsed subtitle: first start time — last end time
    final String subtitle;
    if (startedCps.isEmpty) {
      subtitle = 'Tidak dimulakan';
    } else {
      final lastEnd = startedCps
          .lastWhere((c) => c.endTime != null, orElse: () => startedCps.last)
          .endTime;
      subtitle = '${fmtTime(startedCps.first.startTime)} — '
          '${lastEnd != null ? fmtTime(lastEnd) : '—'}';
    }

    final leading = CircleAvatar(
      radius: 14,
      backgroundColor: groupColor,
      child: Text(
        '$completeCount/$total',
        style: const TextStyle(
            color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
    final title = Text(label,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13));
    final sub =
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey));
    final rounds = [
      for (final n in cpNums)
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: cpMap[n] != null
              ? _CheckpointTile(
                  cp: cpMap[n]!,
                  onEdit: onEdit != null ? () => onEdit!(cpMap[n]!) : null,
                )
              : _SkippedCheckpointTile(cpNum: n, name: checkpointName(n)),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        child: expanded
            ? Column(children: [
                ListTile(leading: leading, title: title, subtitle: sub),
                ...rounds,
              ])
            : ExpansionTile(
                leading: leading,
                title: title,
                subtitle: sub,
                children: rounds,
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
    final startFmt = fmtTime(cp.startTime);
    final endFmt = cp.endTime != null ? fmtTime(cp.endTime!) : null;
    final dur = cp.endTime?.difference(cp.startTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: missed ? Colors.orange : kPrimaryGreen,
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
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Edit masa',
            ),
        ],
      ),
    );
  }
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
            child:
                const Icon(Icons.error_outline, color: Colors.white, size: 14),
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
