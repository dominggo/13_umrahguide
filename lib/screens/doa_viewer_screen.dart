import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/umrah_step.dart';
import '../models/audio_provider.dart';

class DoaViewerScreen extends StatefulWidget {
  final List<DoaItem> duas;
  final int initialIndex;
  final String title;

  const DoaViewerScreen({
    super.key,
    required this.duas,
    required this.initialIndex,
    required this.title,
  });

  @override
  State<DoaViewerScreen> createState() => _DoaViewerScreenState();
}

class _DoaViewerScreenState extends State<DoaViewerScreen> {
  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index >= 0 && index < widget.duas.length) {
      _pageCtrl.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duas.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} / $total',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                total > 10 ? 1 : total,
                (i) => total > 10
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          '${_currentIndex + 1}/$total',
                          style: const TextStyle(color: Color(0xFF1B5E20)),
                        ),
                      )
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentIndex ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _currentIndex
                              ? const Color(0xFF1B5E20)
                              : const Color(0xFF1B5E20).withValues(alpha: 0.3),
                        ),
                      ),
              ),
            ),
          ),

          // Doa pages
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: total,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
                context.read<AudioProvider>().stop();
              },
              itemBuilder: (context, index) {
                return _DoaPage(doa: widget.duas[index]);
              },
            ),
          ),

          // Navigation bar
          _NavBar(
            currentIndex: _currentIndex,
            total: total,
            doa: widget.duas[_currentIndex],
            onPrev: () => _goTo(_currentIndex - 1),
            onNext: () => _goTo(_currentIndex + 1),
          ),
        ],
      ),
    );
  }
}

class _DoaPage extends StatelessWidget {
  final DoaItem doa;
  const _DoaPage({required this.doa});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Title
          Text(
            doa.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 16),

          // Image
          if (doa.imagePath != null)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.hardEdge,
              child: Image.asset(
                doa.imagePath!,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[100],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Gambar tidak dijumpai', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.menu_book, size: 64, color: Color(0xFF1B5E20)),
              ),
            ),

          if (doa.description != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(doa.description!, style: const TextStyle(fontSize: 14, height: 1.6)),
            ),
          ],

          const SizedBox(height: 80), // space for nav bar
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final DoaItem doa;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavBar({
    required this.currentIndex,
    required this.total,
    required this.doa,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final hasAudio = doa.audioPath != null;
    final isPlaying = hasAudio && audio.isCurrentlyPlaying(doa.audioPath!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous button
            IconButton.filled(
              icon: const Icon(Icons.arrow_back_ios_new),
              style: IconButton.styleFrom(
                backgroundColor: currentIndex > 0
                    ? const Color(0xFF1B5E20)
                    : Colors.grey[300],
              ),
              onPressed: currentIndex > 0 ? onPrev : null,
            ),

            // Audio play button (center)
            Expanded(
              child: Center(
                child: hasAudio
                    ? FilledButton.icon(
                        icon: Icon(isPlaying ? Icons.pause : Icons.volume_up),
                        label: Text(isPlaying ? 'Berhenti' : 'Dengar Doa'),
                        style: FilledButton.styleFrom(
                          backgroundColor: isPlaying ? Colors.orange : const Color(0xFF1B5E20),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () => context.read<AudioProvider>().play(doa.audioPath!),
                      )
                    : const Text(
                        'Tiada audio',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
              ),
            ),

            // Next button
            IconButton.filled(
              icon: const Icon(Icons.arrow_forward_ios),
              style: IconButton.styleFrom(
                backgroundColor: currentIndex < total - 1
                    ? const Color(0xFF1B5E20)
                    : Colors.grey[300],
              ),
              onPressed: currentIndex < total - 1 ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}
