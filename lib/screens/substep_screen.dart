import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/umrah_step.dart';
import '../models/audio_provider.dart';
import 'doa_viewer_screen.dart';

class SubStepScreen extends StatelessWidget {
  final UmrahSubStep subStep;
  final String stepTitle;

  const SubStepScreen({super.key, required this.subStep, required this.stepTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subStep.title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: subStep.duas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final doa = subStep.duas[index];
          return _DoaTile(
            doa: doa,
            index: index,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoaViewerScreen(
                  duas: subStep.duas,
                  initialIndex: index,
                  title: subStep.title,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DoaTile extends StatelessWidget {
  final DoaItem doa;
  final int index;
  final VoidCallback onTap;

  const _DoaTile({required this.doa, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final hasAudio = doa.audioPath != null;
    final isPlaying = hasAudio && audio.isCurrentlyPlaying(doa.audioPath!);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Doa image thumbnail or placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: doa.imagePath != null
                    ? Image.asset(
                        doa.imagePath!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doa.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (doa.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        doa.description!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (doa.imagePath != null)
                          const _Badge(icon: Icons.image_outlined, label: 'Gambar'),
                        if (hasAudio) ...[
                          if (doa.imagePath != null) const SizedBox(width: 6),
                          const _Badge(icon: Icons.volume_up_outlined, label: 'Audio'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Quick audio play button
              if (hasAudio)
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: const Color(0xFF1B5E20),
                    size: 36,
                  ),
                  onPressed: () => context.read<AudioProvider>().play(doa.audioPath!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
      child: const Icon(Icons.menu_book, color: Color(0xFF1B5E20), size: 36),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF1B5E20)),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF1B5E20))),
        ],
      ),
    );
  }
}
