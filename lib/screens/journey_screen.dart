import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/umrah_data.dart';
import '../models/journey_models.dart';
import '../models/location_provider.dart';
import '../models/progress_provider.dart';
import '../models/umrah_location.dart';
import '../models/umrah_step.dart';
import '../services/analytics_service.dart';
import 'journey_summary_screen.dart';
import 'step_detail_screen.dart';
import 'doa_viewer_screen.dart';
import '../models/journey_history_provider.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final prog = context.watch<ProgressProvider>();
    final currentZone = loc.currentZone;
    final isActive = loc.isJourneyActive;

    // Journey steps: ihram, tawaf, solat_tawaf, saie, tahallul
    const journeyStepIds = {
      'ihram',
      'tawaf',
      'solat_tawaf',
      'saie',
      'tahallul'
    };
    final journeySteps =
        umrahSteps.where((s) => journeyStepIds.contains(s.id)).toList();

    final missedCps = loc.missedCheckpoints;
    final hasMissed = missedCps.isNotEmpty;

    return Column(
      children: [
        // 1. Compact GPS row
        _CompactGpsRow(
          gpsAvailable: loc.gpsAvailable,
          currentZone: currentZone,
          onManualSelect: () => _showManualZoneDialog(context, loc),
        ),

        // 2. "Mulakan Umrah" button (idle only)
        if (!isActive)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mulakan Umrah'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF1B5E20),
              ),
              onPressed: () async {
                if (!loc.gpsAvailable) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'GPS tidak tersedia. Perjalanan direkod tanpa GPS.'),
                  ));
                }
                await loc.startJourney();
                AnalyticsService.logJourneyStarted();
              },
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
                      color: const Color(0xFF1B5E20),
                    ),
                    title: Text(
                      (loc.lastIncompleteCheckpoint != null ||
                              loc.nextUnstartedCheckpoint(17) != null)
                          ? 'Sambung Umrah'
                          : 'Selesai',
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
              if (hasMissed) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Peringatan Tertinggal',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                _MissedCheckpointCard(
                  missedCheckpoints: missedCps,
                  onReopen: (cp) => _reopenCheckpoint(context, loc, cp),
                ),
              ],

              // Progress header
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Perkembangan Umrah',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),

              // 5 journey step tiles — tappable
              ...journeySteps.asMap().entries.map((entry) {
                final stepNum = entry.key + 1;
                final step = entry.value;
                final isTawaf = step.id == 'tawaf';
                final isSaie = step.id == 'saie';

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1B5E20),
                        child: Text(
                          '$stepNum',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(step.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: (isTawaf || isSaie)
                          ? _CheckpointDots(
                              step: step,
                              locationProvider: loc,
                            )
                          : Text(step.subtitle,
                              style: const TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => _openStep(context, step),
                    ),
                  ),
                );
              }),
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
                onPressed: () => _endJourney(context, loc, prog),
              ),
            ),
          ),
      ],
    );
  }

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
    final nextNum = loc.nextUnstartedCheckpoint(17);
    if (nextNum == null) return 'Semua selesai';
    for (final step in umrahSteps) {
      for (final sub in step.subSteps) {
        for (final doa in sub.duas) {
          if (doa.checkPointStart == nextNum) {
            return doa.checkPointName ?? sub.title;
          }
        }
      }
    }
    return 'Checkpoint $nextNum';
  }

  void _openLastCheckpoint(BuildContext context, LocationProvider loc) {
    final incomplete = loc.lastIncompleteCheckpoint;

    if (incomplete != null) {
      _openCheckpointDoa(context, incomplete.checkpointNum);
      return;
    }

    // No incomplete checkpoint — find the next unstarted one
    final nextNum = loc.nextUnstartedCheckpoint(17);
    if (nextNum != null) {
      _openCheckpointDoa(context, nextNum);
      return;
    }

    // All 17 checkpoints completed — open ihram as fallback
    final ihram = umrahSteps.firstWhere((s) => s.id == 'ihram');
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoaViewerScreen(
            duas: const [],
            initialIndex: 0,
            title: ihram.title,
            stepId: ihram.id,
            fullStep: ihram,
            fromJourney: true,
          ),
        ));
  }

  void _reopenCheckpoint(
      BuildContext context, LocationProvider loc, CheckpointRecord cp) {
    _openCheckpointDoa(context, cp.checkpointNum);
  }

  /// Navigate to the DoaViewerScreen for the doa that has checkPointStart == [cpNum].
  void _openCheckpointDoa(BuildContext context, int cpNum) {
    for (final step in umrahSteps) {
      int flatIndex = 0;
      for (final sub in step.subSteps) {
        for (int di = 0; di < sub.duas.length; di++) {
          if (sub.duas[di].checkPointStart == cpNum) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoaViewerScreen(
                    duas: const [],
                    initialIndex: flatIndex + di,
                    title: step.title,
                    stepId: step.id,
                    fullStep: step,
                    fromJourney: true,
                  ),
                ));
            return;
          }
        }
        flatIndex += sub.duas.length;
      }
    }
  }

  Future<void> _endJourney(
      BuildContext context, LocationProvider loc, ProgressProvider prog) async {
    final history = context.read<JourneyHistoryProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tamatkan Perjalanan?'),
        content: const Text(
            'Adakah anda pasti ingin menamatkan perjalanan umrah ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Selesai')),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final record = await loc.finalizeJourney();
    await history.addOrUpdateJourney(record);
    AnalyticsService.logJourneyCompleted(
        checkpointsCompleted: record.checkpoints.where((c) => c.isCompleted).length);
    if (context.mounted) await prog.clearProgress();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JourneySummaryScreen(
            startTime: record.startTime,
            endTime: record.endTime,
            gpsTrack: record.gpsTrack,
            checkpoints: record.checkpoints,
            journeyId: record.id,
          ),
        ),
      );
    }
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
            leading: const Icon(Icons.place, color: Color(0xFF1B5E20)),
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
  final UmrahLocation? currentZone;
  final VoidCallback onManualSelect;

  const _CompactGpsRow({
    required this.gpsAvailable,
    required this.currentZone,
    required this.onManualSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: gpsAvailable ? const Color(0xFFE8F5E9) : Colors.grey[100],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            gpsAvailable ? Icons.gps_fixed : Icons.gps_off,
            size: 14,
            color: gpsAvailable ? const Color(0xFF1B5E20) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            gpsAvailable ? 'GPS Aktif' : 'GPS Tidak Aktif',
            style: TextStyle(
              fontSize: 12,
              color: gpsAvailable ? const Color(0xFF1B5E20) : Colors.grey,
            ),
          ),
          if (currentZone != null) ...[
            Text(
              ' · ${currentZone!.nameMalay}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
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

/// Dots indicating checkpoint completion status for tawaf/saie rounds.
class _CheckpointDots extends StatelessWidget {
  final UmrahStep step;
  final LocationProvider locationProvider;

  const _CheckpointDots({required this.step, required this.locationProvider});

  @override
  Widget build(BuildContext context) {
    // Collect all checkPointEnd nums that appear in this step's duas
    final endNums = <int>[];
    for (final sub in step.subSteps) {
      for (final doa in sub.duas) {
        if (doa.checkPointEnd != null) endNums.add(doa.checkPointEnd!);
      }
    }

    if (endNums.isEmpty) {
      return Text(step.subtitle, style: const TextStyle(fontSize: 12));
    }

    return Row(
      children: endNums.map((cpNum) {
        final completed = locationProvider.isCheckpointCompleted(cpNum);
        final started = locationProvider.isCheckpointStarted(cpNum);
        final color = completed
            ? const Color(0xFF1B5E20)
            : started
                ? Colors.orange
                : Colors.grey[300]!;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: CircleAvatar(backgroundColor: color, radius: 5),
        );
      }).toList(),
    );
  }
}

class _MissedCheckpointCard extends StatelessWidget {
  final List<CheckpointRecord> missedCheckpoints;
  final void Function(CheckpointRecord cp) onReopen;

  const _MissedCheckpointCard({
    required this.missedCheckpoints,
    required this.onReopen,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>(); // <-- Get it here

    // Filter first
    final visibleCheckpoints = missedCheckpoints
        .where((cp) => cp.name != loc.lastIncompleteCheckpoint?.name)
        .toList();

    // Hide card if nothing to show after filtering
    if (visibleCheckpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.orange[50],
      child: Column(
        children: visibleCheckpoints
            .map((cp) => ListTile(
                  leading:
                      const Icon(Icons.warning_amber, color: Colors.orange),
                  title: Text('${cp.name} belum diselesaikan'),
                  trailing: TextButton(
                    onPressed: () => onReopen(cp),
                    child: const Text('Semula'),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
