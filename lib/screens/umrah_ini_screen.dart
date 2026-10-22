import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/umrah_data.dart';
import '../models/journey_models.dart';
import '../models/location_provider.dart';
import '../models/umrah_location.dart';
import '../models/umrah_step.dart';
import '../services/analytics_service.dart';
import '../utils/format.dart';
import 'step_detail_screen.dart';
import 'journey_actions.dart';

class UmrahIniScreen extends StatelessWidget {
  const UmrahIniScreen({super.key});

  // Journey steps: ihram, tawaf, solat_tawaf, saie, tahallul
  static const _journeyStepIds = {
    'ihram',
    'tawaf',
    'solat_tawaf',
    'saie',
    'tahallul'
  };

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final currentZone = loc.currentZone;
    final isActive = loc.isUmrahActive;
    final isWidaActive = loc.isWidaActive;

    final journeySteps =
        umrahSteps.where((s) => _journeyStepIds.contains(s.id)).toList();

    final missedCps = isActive ? loc.missedCheckpoints : <CheckpointRecord>[];
    final hasMissed = missedCps.isNotEmpty;

    return Column(
      children: [
        // 1. Compact GPS row
        _CompactGpsRow(
          gpsAvailable: loc.gpsAvailable,
          signal: loc.gpsSignal,
          currentZone: currentZone,
          onManualSelect: () => _showManualZoneDialog(context, loc),
        ),
        if (loc.isJourneyActive) const _ScreenOnBanner(),

        // 2. "Mulakan Umrah" button (idle only)
        if (!isActive)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulakan Umrah'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: kPrimaryGreen,
              ),
              onPressed: isWidaActive ? null : () => startJourney(context),
            ),
          ),
        if (!isActive && isWidaActive)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              "Tamatkan Tawaf Wida' dahulu sebelum memulakan Umrah.",
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),

        // 3. Scrollable content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              // Resume card — always visible when journey is active
              if (isActive)
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  color: const Color(0xFFE8F5E9),
                  child: ListTile(
                    leading: Icon(
                      loc.lastIncompleteCheckpoint != null
                          ? Icons.play_circle_outline
                          : Icons.check_circle_outline,
                      color: kPrimaryGreen,
                    ),
                    title: Text(
                      _hasRemaining(loc) ? 'Sambung Umrah' : 'Selesai',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      _nextCheckpointSubtitle(loc),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _openLastCheckpoint(context, loc),
                  ),
                ),

              // Missed checkpoints ABOVE progress
              if (hasMissed)
                _MissedCheckpointCard(
                  missedCheckpoints: missedCps,
                  currentNum: loc.lastIncompleteCheckpoint?.checkpointNum,
                  onReopen: (cp) => openCheckpoint(context, cp.checkpointNum),
                ),

              // Progress header
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Perkembangan Umrah',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),

              // 5 journey step tiles — tappable
              for (final (i, step) in journeySteps.indexed)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryGreen,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(step.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: (step.id == 'tawaf' || step.id == 'saie')
                          ? _CheckpointDots(step: step, locationProvider: loc)
                          : Text(step.subtitle,
                              style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => _openStep(context, step),
                    ),
                  ),
                ),

              // Tawaf Wida' — independent of any Umrah journey
              _buildWidaCard(context, loc),
            ],
          ),
        ),

        // 4. "Selesai Ibadah Umrah" fixed at bottom (active only)
        if (isActive)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
                label: const Text('Selesai Ibadah Umrah',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () => finishJourney(context),
              ),
            ),
          ),
      ],
    );
  }

  bool _hasRemaining(LocationProvider loc) =>
      loc.lastIncompleteCheckpoint != null ||
      loc.nextUnstartedCheckpoint() != null;

  void _openStep(BuildContext context, UmrahStep step) {
    AnalyticsService.logStepViewed(stepId: step.id);
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StepDetailScreen(step: step, fromJourney: true),
        ));
  }

  /// Returns subtitle text for the resume card.
  String _nextCheckpointSubtitle(LocationProvider loc) {
    final incomplete = loc.lastIncompleteCheckpoint;
    if (incomplete != null) return incomplete.name;
    final nextNum = loc.nextUnstartedCheckpoint();
    if (nextNum == null) return 'Semua selesai';
    return checkpointName(nextNum);
  }

  void _openLastCheckpoint(BuildContext context, LocationProvider loc) {
    final num = loc.lastIncompleteCheckpoint?.checkpointNum ??
        loc.nextUnstartedCheckpoint() ??
        // All checkpoints completed — open the first one of this kind
        loc.journeyKind.firstCp;
    openCheckpoint(context, num);
  }

  /// Card for the standalone Tawaf Wida' session. Wida' is not part of an Umrah
  /// journey: several Umrahs may precede a single Wida'.
  Widget _buildWidaCard(BuildContext context, LocationProvider loc) {
    final widaStep = umrahSteps.firstWhere((s) => s.id == 'tawaf_wida');
    final isWidaActive = loc.isWidaActive;
    final umrahBusy = loc.isUmrahActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "Tawaf Wida'",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: kPrimaryGreen,
                    child: Icon(Icons.waving_hand, color: Colors.white, size: 18),
                  ),
                  title: Text(widaStep.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: isWidaActive
                      ? _WidaDots(locationProvider: loc)
                      : Text(
                          '${widaStep.subtitle} — berasingan daripada Umrah',
                          style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => _openStep(context, widaStep),
                ),
                if (isWidaActive) ...[
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.play_circle_outline,
                        color: kPrimaryGreen),
                    title: Text(
                      _hasRemaining(loc) ? "Sambung Tawaf Wida'" : 'Selesai',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(_nextCheckpointSubtitle(loc),
                        style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => _openLastCheckpoint(context, loc),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.stop_circle_outlined,
                          color: Colors.red),
                      label: const Text("Selesai Tawaf Wida'",
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: () => finishJourney(context),
                    ),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text("Mulakan Tawaf Wida'"),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                            backgroundColor: kPrimaryGreen,
                          ),
                          onPressed: umrahBusy
                              ? null
                              : () => startJourney(context,
                                  kind: JourneyKind.wida),
                        ),
                        if (umrahBusy)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              "Tamatkan Umrah dahulu sebelum memulakan Tawaf Wida'.",
                              style:
                                  TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showManualZoneDialog(BuildContext context, LocationProvider locProv) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
            title: Text(loc.nameMalay),
            onTap: () {
              locProv.manualOverrideZone(loc);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}

class _CompactGpsRow extends StatelessWidget {
  final bool gpsAvailable;
  final GpsSignal signal;
  final UmrahLocation? currentZone;
  final VoidCallback onManualSelect;

  const _CompactGpsRow({
    required this.gpsAvailable,
    required this.signal,
    required this.currentZone,
    required this.onManualSelect,
  });

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String label, Color fg, Color bg) =
        !gpsAvailable
            ? (Icons.gps_off, 'GPS Tidak Aktif', Colors.grey, Colors.grey[100]!)
            : switch (signal) {
                GpsSignal.lost => (
                    Icons.gps_not_fixed,
                    'Isyarat GPS hilang',
                    Colors.orange[800]!,
                    Colors.orange[50]!,
                  ),
                GpsSignal.recovered => (
                    Icons.gps_fixed,
                    'GPS disambung semula',
                    kPrimaryGreen,
                    const Color(0xFFC8E6C9),
                  ),
                GpsSignal.ok => (
                    Icons.gps_fixed,
                    'GPS Aktif',
                    kPrimaryGreen,
                    const Color(0xFFE8F5E9),
                  ),
              };

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: fg)),
          if (currentZone != null)
            Flexible(
              child: Text(
                ' · ${currentZone!.nameMalay}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: onManualSelect,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              textStyle: const TextStyle(fontSize: 11),
            ),
            child: const Text('Lokasi Manual'),
          ),
        ],
      ),
    );
  }
}

/// Reminder shown while a session runs: GPS only records with the screen on.
class _ScreenOnBanner extends StatelessWidget {
  const _ScreenOnBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF8E1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: const Row(
        children: [
          Icon(Icons.screen_lock_portrait, size: 14, color: Colors.brown),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              "Jangan kunci skrin atau tutup aplikasi semasa Tawaf dan Sa'ie "
              '— GPS hanya merekod ketika skrin menyala.',
              style: TextStyle(fontSize: 11, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dots indicating checkpoint completion status for tawaf/saie rounds.
class _CheckpointDots extends StatelessWidget {
  final UmrahStep step;
  final LocationProvider locationProvider;

  const _CheckpointDots({required this.step, required this.locationProvider});

  @override
  Widget build(BuildContext context) {
    // Collect all checkPointEnd nums that appear in this step's duas
    final endNums = <int>[
      for (final sub in step.subSteps)
        for (final doa in sub.duas)
          if (doa.checkPointEnd != null) doa.checkPointEnd!,
    ];

    if (endNums.isEmpty) {
      return Text(step.subtitle, style: const TextStyle(fontSize: 12));
    }
    return _StatusDots(nums: endNums, locationProvider: locationProvider);
  }
}

/// Dots for the 7 rounds of a Tawaf Wida' session (CP18–24).
class _WidaDots extends StatelessWidget {
  final LocationProvider locationProvider;

  const _WidaDots({required this.locationProvider});

  @override
  Widget build(BuildContext context) => _StatusDots(
        nums: [
          for (int cp = JourneyKind.wida.firstCp;
              cp <= JourneyKind.wida.lastCp;
              cp++)
            cp,
        ],
        locationProvider: locationProvider,
      );
}

/// Green = completed, orange = started, grey = not started.
class _StatusDots extends StatelessWidget {
  final List<int> nums;
  final LocationProvider locationProvider;

  const _StatusDots({required this.nums, required this.locationProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final cp in nums)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              backgroundColor: locationProvider.isCheckpointCompleted(cp)
                  ? kPrimaryGreen
                  : locationProvider.isCheckpointStarted(cp)
                      ? Colors.orange
                      : Colors.grey[300]!,
              radius: 5,
            ),
          ),
      ],
    );
  }
}

class _MissedCheckpointCard extends StatelessWidget {
  final List<CheckpointRecord> missedCheckpoints;

  /// The in-progress checkpoint; it's not "missed", so it is left out.
  final int? currentNum;
  final void Function(CheckpointRecord cp) onReopen;

  const _MissedCheckpointCard({
    required this.missedCheckpoints,
    required this.currentNum,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final visible =
        missedCheckpoints.where((cp) => cp.checkpointNum != currentNum).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Peringatan Tertinggal',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.orange[50],
          child: Column(
            children: [
              for (final cp in visible)
                ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.orange),
                  title: Text('${cp.name} belum diselesaikan'),
                  trailing: TextButton(
                    onPressed: () => onReopen(cp),
                    child: const Text('Semula'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
