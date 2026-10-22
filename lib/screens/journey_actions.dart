import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/umrah_data.dart';
import '../utils/format.dart';
import '../models/journey_history_provider.dart';
import '../models/journey_models.dart';
import '../models/location_provider.dart';
import '../services/analytics_service.dart';
import 'doa_viewer_screen.dart';
import 'umrah_tamat_screen.dart';

/// Shared journey flows used by the Umrah tab and the doa viewer.

/// Opens the doa that starts checkpoint [cpNum] in journey mode.
void openCheckpoint(BuildContext context, int cpNum) {
  final loc = checkpointStartLocation(cpNum);
  if (loc == null) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DoaViewerScreen(
        duas: const [],
        initialIndex: loc.flatIndex,
        title: loc.step.title,
        stepId: loc.step.id,
        fullStep: loc.step,
        fromJourney: true,
      ),
    ),
  );
}

const _screenNoticeKey = 'hide_screen_on_notice';

/// Starts a session of [kind], shows the keep-screen-on notice (until the
/// user ticks "Jangan tunjuk lagi") and, if [openFirstCheckpoint], opens the
/// doa of the first checkpoint.
Future<void> startJourney(
  BuildContext context, {
  JourneyKind kind = JourneyKind.umrah,
  bool openFirstCheckpoint = true,
}) async {
  final loc = context.read<LocationProvider>();
  if (!loc.gpsAvailable) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('GPS tidak tersedia. Perjalanan direkod tanpa GPS.'),
    ));
  }
  await loc.startJourney(kind: kind);
  AnalyticsService.logJourneyStarted(kind: kind);
  if (!context.mounted) return;
  await _showScreenOnNotice(context);
  if (openFirstCheckpoint && context.mounted) {
    openCheckpoint(context, kind.firstCp);
  }
}

Future<void> _showScreenOnNotice(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_screenNoticeKey) ?? false) return;
  if (!context.mounted) return;
  var hide = false;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        icon: const Icon(Icons.screen_lock_portrait, color: kPrimaryGreen),
        title: const Text('Jangan tutup skrin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pastikan skrin tidak dikunci dan aplikasi tidak ditutup semasa "
              "Tawaf dan Sa'ie. GPS berhenti merekod apabila skrin dikunci "
              'atau aplikasi ditutup, dan laluan anda akan terputus.\n\n'
              'Skrin akan kekal menyala sepanjang perjalanan.',
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: hide,
              onChanged: (v) => setLocal(() => hide = v ?? false),
              title: const Text('Jangan tunjuk lagi'),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Faham'),
          ),
        ],
      ),
    ),
  );
  if (hide) await prefs.setBool(_screenNoticeKey, true);
}

/// Asks for confirmation, then finalizes the active session, saves it to
/// history and shows its summary on top of Home. If [beforeFinalize] is set
/// it runs after the user confirms (e.g. to record the last checkpoint end).
/// Returns false if the user cancelled or saving failed.
Future<bool> finishJourney(
  BuildContext context, {
  Future<void> Function()? beforeFinalize,
}) async {
  final loc = context.read<LocationProvider>();
  final history = context.read<JourneyHistoryProvider>();
  if (!loc.isJourneyActive) return false;
  final kindLabel =
      loc.journeyKind == JourneyKind.wida ? "Tawaf Wida'" : 'Umrah';

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Tamatkan $kindLabel?'),
      content: Text('Adakah anda pasti ingin menamatkan $kindLabel ini? '
          'Rekod akan disimpan dalam Sejarah.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Tidak'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.green[700]),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ya, Tamatkan'),
        ),
      ],
    ),
  );
  if (confirm != true) return false;

  if (beforeFinalize != null) await beforeFinalize();
  final record = await loc.finalizeJourney();
  try {
    await history.addOrUpdateJourney(record);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal simpan rekod: $e')),
      );
    }
    return false;
  }
  AnalyticsService.logJourneyCompleted(
    checkpointsCompleted: record.checkpoints.where((c) => c.isCompleted).length,
    kind: record.kind,
  );

  if (context.mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => UmrahTamatScreen(
          startTime: record.startTime,
          endTime: record.endTime,
          gpsTrack: record.gpsTrack,
          checkpoints: record.checkpoints,
          journeyId: record.id,
          kind: record.kind,
        ),
      ),
      (route) => route.isFirst,
    );
  }
  return true;
}
