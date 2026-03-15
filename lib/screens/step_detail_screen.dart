import 'package:flutter/material.dart';
import '../models/umrah_step.dart';
import 'doa_list_screen.dart';
import 'doa_viewer_screen.dart';

class StepDetailScreen extends StatelessWidget {
  final UmrahStep step;
  final bool fromJourney;

  const StepDetailScreen({
    super.key,
    required this.step,
    this.fromJourney = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(step.title),
      ),
      body: Column(
        children: [
          // Step header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF1B5E20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(step.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.list,
                      label: '${step.subSteps.length} Bahagian',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.record_voice_over,
                      label: '${_countDuas(step)} Doa',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-steps list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: step.subSteps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sub = step.subSteps[index];
                return _SubStepTile(
                  subStep: sub,
                  number: index + 1,
                  onTap: () => _onSubstepTap(context, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onSubstepTap(BuildContext context, int subIndex) {
    if (fromJourney) {
      // Compute flat index of the first doa in this substep
      int flatIndex = 0;
      for (int i = 0; i < subIndex; i++) {
        flatIndex += step.subSteps[i].duas.length;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoaViewerScreen(
            duas: const [],
            initialIndex: flatIndex,
            title: step.title,
            stepId: step.id,
            fullStep: step,
            fromJourney: true,
          ),
        ),
      );
    } else {
      final sub = step.subSteps[subIndex];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoaListScreen(
            subStep: sub,
            stepTitle: step.title,
            stepId: step.id,
          ),
        ),
      );
    }
  }

  int _countDuas(UmrahStep step) {
    return step.subSteps.fold(0, (sum, sub) => sum + sub.duas.length);
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SubStepTile extends StatelessWidget {
  final UmrahSubStep subStep;
  final int number;
  final VoidCallback onTap;

  const _SubStepTile({required this.subStep, required this.number, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1B5E20),
          child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(subStep.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${subStep.duas.length} doa',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
