import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/umrah_data.dart';
import '../models/location_provider.dart';
import '../models/progress_provider.dart';
import '../models/umrah_location.dart';
import 'guide_flow_screen.dart';
import 'journey_summary_screen.dart';

class JourneyScreen extends StatelessWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocationProvider>();
    final prog = context.watch<ProgressProvider>();
    final currentZone = loc.currentZone;

    return Scaffold(
      appBar: AppBar(title: const Text('Perjalanan Umrah')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // GPS status
          _GpsStatusCard(
            gpsAvailable: loc.gpsAvailable,
            currentZone: currentZone,
            isJourneyActive: loc.isJourneyActive,
            onManualSelect: () => _showManualZoneDialog(context, loc),
          ),

          const SizedBox(height: 16),

          // Journey control
          if (!loc.isJourneyActive)
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Masuk ke Masjid untuk Mulakan Tawaf'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _startJourney(context, loc, prog),
            )
          else
            OutlinedButton.icon(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              label: const Text('Selesai Ibadah Umrah', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _endJourney(context, loc, prog),
            ),

          const SizedBox(height: 20),

          // Progress timeline
          const Text(
            'Perkembangan Umrah',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ...List.generate(umrahSteps.length, (i) {
            final step = umrahSteps[i];
            final isTawaf = step.id == 'tawaf';
            final isSaie = step.id == 'saie';
            final hasSkipped = isTawaf
                ? prog.hasSkippedRounds('tawaf')
                : isSaie
                    ? prog.hasSkippedRounds('saie')
                    : false;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1B5E20),
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(step.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: (isTawaf || isSaie)
                      ? _RoundDots(
                          prefix: isTawaf ? 'tawaf' : 'saie',
                          total: 7,
                          progressProvider: prog,
                        )
                      : Text(step.subtitle, style: const TextStyle(fontSize: 12)),
                  trailing: hasSkipped
                      ? const Icon(Icons.warning_amber, color: Colors.orange, size: 20)
                      : null,
                ),
              ),
            );
          }),

          // Missed reminders
          if (_hasMissed(prog)) ...[
            const SizedBox(height: 16),
            const Text(
              'Peringatan Tertinggal',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            _MissedReminderCard(progressProvider: prog),
          ],
        ],
      ),
    );
  }

  bool _hasMissed(ProgressProvider prog) =>
      prog.hasSkippedRounds('tawaf') || prog.hasSkippedRounds('saie');

  Future<void> _startJourney(BuildContext context, LocationProvider loc, ProgressProvider prog) async {
    await loc.startJourney();
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GuideFlowScreen(steps: umrahSteps, initialStepIndex: prog.stepIndex),
        ),
      );
    }
  }

  Future<void> _endJourney(BuildContext context, LocationProvider loc, ProgressProvider prog) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tamatkan Perjalanan?'),
        content: const Text('Adakah anda pasti ingin menamatkan perjalanan umrah ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Selesai')),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final result = await loc.endJourney();
    await prog.clearProgress();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => JourneySummaryScreen(
            startTime: result.start ?? DateTime.now(),
            endTime: DateTime.now(),
            gpsTrack: result.track,
            events: result.events,
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

class _GpsStatusCard extends StatelessWidget {
  final bool gpsAvailable;
  final UmrahLocation? currentZone;
  final bool isJourneyActive;
  final VoidCallback onManualSelect;

  const _GpsStatusCard({
    required this.gpsAvailable,
    required this.currentZone,
    required this.isJourneyActive,
    required this.onManualSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: gpsAvailable ? const Color(0xFFE8F5E9) : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              gpsAvailable ? Icons.gps_fixed : Icons.gps_off,
              color: gpsAvailable ? const Color(0xFF1B5E20) : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gpsAvailable ? 'GPS Aktif' : 'GPS Tidak Aktif',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: gpsAvailable ? const Color(0xFF1B5E20) : Colors.grey,
                    ),
                  ),
                  Text(
                    currentZone != null
                        ? 'Anda di: ${currentZone!.nameMalay}'
                        : 'Di luar kawasan',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onManualSelect,
              child: const Text('Pilih Manual', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundDots extends StatelessWidget {
  final String prefix;
  final int total;
  final ProgressProvider progressProvider;

  const _RoundDots({required this.prefix, required this.total, required this.progressProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final key = '${prefix}_${i + 1}';
        final status = progressProvider.getRoundStatus(key);
        final color = status == RoundStatus.confirmed
            ? const Color(0xFF1B5E20)
            : status == RoundStatus.skipped
                ? Colors.orange
                : Colors.grey[300]!;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: CircleAvatar(backgroundColor: color, radius: 5),
        );
      }),
    );
  }
}

class _MissedReminderCard extends StatelessWidget {
  final ProgressProvider progressProvider;
  const _MissedReminderCard({required this.progressProvider});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int i = 1; i <= 7; i++) {
      if (progressProvider.getRoundStatus('tawaf_$i') == RoundStatus.skipped) {
        items.add(ListTile(
          leading: const Icon(Icons.warning_amber, color: Colors.orange),
          title: Text('Tawaf Pusingan $i belum disahkan'),
          trailing: TextButton(
            onPressed: () => progressProvider.confirmRound('tawaf_$i'),
            child: const Text('Ulangi'),
          ),
        ));
      }
      if (progressProvider.getRoundStatus('saie_$i') == RoundStatus.skipped) {
        items.add(ListTile(
          leading: const Icon(Icons.warning_amber, color: Colors.orange),
          title: Text("Sa'ie Ke-$i belum disahkan"),
          trailing: TextButton(
            onPressed: () => progressProvider.confirmRound('saie_$i'),
            child: const Text('Ulangi'),
          ),
        ));
      }
    }
    return Card(
      color: Colors.orange[50],
      child: Column(children: items),
    );
  }
}
