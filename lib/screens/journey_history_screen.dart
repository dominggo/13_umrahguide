import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/journey_history_provider.dart';
import '../models/journey_record.dart';
import 'journey_summary_screen.dart';

class JourneyHistoryScreen extends StatelessWidget {
  const JourneyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<JourneyHistoryProvider>();
    final journeys = history.journeys;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sejarah Umrah — ${history.totalUmrahCount} kali selesai'),
      ),
      body: journeys.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Belum ada rekod perjalanan umrah', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: journeys.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _JourneyTile(
                record: journeys[i],
                umrahNum: journeys.length - i,
              ),
            ),
    );
  }
}

class _JourneyTile extends StatelessWidget {
  final UmrahJourneyRecord record;
  final int umrahNum;

  const _JourneyTile({required this.record, required this.umrahNum});

  @override
  Widget build(BuildContext context) {
    final dur = record.totalDuration;
    final dist = record.totalDistanceKm;

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Padam Rekod?'),
          content: Text('Adakah anda pasti ingin memadam rekod Umrah ke-$umrahNum?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Padam'),
            ),
          ],
        ),
      ),
      onDismissed: (_) => context.read<JourneyHistoryProvider>().deleteJourney(record.id),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JourneySummaryScreen(
                startTime: record.startTime,
                endTime: record.endTime,
                gpsTrack: record.gpsTrack,
                events: record.events,
                journeyId: record.id,
              ),
            ),
          ),
          onLongPress: () => _showEditSheet(context, record),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1B5E20),
                  radius: 22,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mosque, color: Colors.white, size: 14),
                      Text('$umrahNum', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Umrah ke-$umrahNum',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        _formatDate(record.startTime),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoChip(label: '${dur.inHours}j ${dur.inMinutes.remainder(60)}min'),
                          if (dist > 0) ...[
                            const SizedBox(width: 6),
                            _InfoChip(label: '${dist.toStringAsFixed(2)} km'),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context, UmrahJourneyRecord record) async {
    DateTime newStart = record.startTime;
    DateTime newEnd = record.endTime;

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
              const Text('Edit Masa Perjalanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.play_arrow, color: Color(0xFF1B5E20)),
                title: const Text('Masa Mula'),
                subtitle: Text(_formatDate(newStart)),
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
                      setLocalState(() => newStart = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.stop, color: Colors.red),
                title: const Text('Masa Tamat'),
                subtitle: Text(_formatDate(newEnd)),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: newEnd,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null && ctx.mounted) {
                    final t = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(newEnd),
                    );
                    if (t != null) {
                      setLocalState(() => newEnd = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await context.read<JourneyHistoryProvider>().updateJourney(
                      record.id,
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

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF1B5E20))),
    );
  }
}
