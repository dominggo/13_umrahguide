import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../models/umrah_step.dart';
import '../models/audio_provider.dart';
import '../models/bookmark_provider.dart';
import '../models/progress_provider.dart';

class DoaViewerScreen extends StatefulWidget {
  final List<DoaItem> duas;
  final int initialIndex;
  final String title;
  /// Optional: for round tracking (e.g. "tawaf", "saie")
  final String? roundPrefix;
  /// Optional: round number (1-7) for round completion dialog
  final int? roundNumber;
  /// Step id for bookmark key building
  final String? stepId;
  /// Substep id for bookmark key building
  final String? substepId;

  const DoaViewerScreen({
    super.key,
    required this.duas,
    required this.initialIndex,
    required this.title,
    this.roundPrefix,
    this.roundNumber,
    this.stepId,
    this.substepId,
  });

  @override
  State<DoaViewerScreen> createState() => _DoaViewerScreenState();
}

class _DoaViewerScreenState extends State<DoaViewerScreen> {
  late PageController _pageCtrl;
  late int _currentIndex;
  bool _repeat = false;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);

    // Subscribe to audio completion for auto-advance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _completeSub = context.read<AudioProvider>().onTrackComplete.listen((_) => _onTrackComplete());
    });
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Auto-play group logic ─────────────────────────────────────────────────

  /// Returns [start, end] indices for the group that contains [index].
  /// A group is a contiguous sequence of DoaItems where autoPlay == true.
  (int, int) _groupRange(int index) {
    final duas = widget.duas;

    // Find start: walk backward while autoPlay is true
    int start = index;
    while (start > 0 && duas[start].autoPlay && duas[start - 1].autoPlay) {
      start--;
    }

    // Find end: walk forward while autoPlay is true
    int end = index;
    while (end < duas.length - 1 && duas[end].autoPlay && duas[end + 1].autoPlay) {
      end++;
    }

    return (start, end);
  }

  void _onTrackComplete() {
    if (!mounted) return;
    final duas = widget.duas;
    final curDoa = duas[_currentIndex];

    // If current doa is a divider (autoPlay=false), don't auto-advance
    if (!curDoa.autoPlay) return;

    final (groupStart, groupEnd) = _groupRange(_currentIndex);

    if (_currentIndex < groupEnd) {
      // Advance to next in group
      final next = _currentIndex + 1;
      if (duas[next].autoPlay) {
        _goTo(next, autoPlay: true);
      }
    } else if (_repeat) {
      // Repeat: jump to group start
      _goTo(groupStart, autoPlay: true);
    }
    // else: end of group, no repeat — just stop
  }

  void _goTo(int index, {bool autoPlay = false}) {
    if (index < 0 || index >= widget.duas.length) return;
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    if (autoPlay) {
      final doa = widget.duas[index];
      if (doa.audioPath != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<AudioProvider>().play(doa.audioPath!);
        });
      }
    }
  }

  void _onPageChanged(int i) {
    setState(() => _currentIndex = i);
    context.read<AudioProvider>().stop();

    // Check round completion when reaching last doa
    if (_isRoundSubstep && i == widget.duas.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkRoundCompletion());
    }
  }

  bool get _isRoundSubstep =>
      widget.roundPrefix != null && widget.roundNumber != null;

  String get _roundKey => '${widget.roundPrefix}_${widget.roundNumber}';

  Future<void> _checkRoundCompletion() async {
    if (!mounted || !_isRoundSubstep) return;
    final prog = context.read<ProgressProvider>();
    if (prog.isRoundComplete(_roundKey)) return;

    final prefix = widget.roundPrefix!;
    final num = widget.roundNumber!;
    final label = prefix == 'tawaf'
        ? 'Tawaf Pusingan $num'
        : prefix == 'tawaf_wida'
            ? "Tawaf Wida' Pusingan $num"
            : "Sa'ie Ke-$num";
    final question = prefix == 'tawaf'
        ? 'Adakah anda telah melengkapkan tawaf pusingan $num?'
        : prefix == 'tawaf_wida'
            ? "Adakah anda telah melengkapkan tawaf wida' pusingan $num?"
            : "Adakah anda telah melengkapkan sa'ie ke-$num?";

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: Text(question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == true) {
      await prog.confirmRound(_roundKey);
    } else {
      await prog.skipRound(_roundKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.duas.length;
    final prog = context.watch<ProgressProvider>();
    final bm = context.watch<BookmarkProvider>();

    final currentDoa = widget.duas[_currentIndex];
    final bmKey = widget.stepId != null && widget.substepId != null
        ? BookmarkProvider.keyFor(widget.stepId!, widget.substepId!, currentDoa.title)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Round indicator for Tawaf/Sa'ie
          if (_isRoundSubstep)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _RoundStatusIndicator(
                prefix: widget.roundPrefix!,
                total: 7,
                progressProvider: prog,
              ),
            ),
          // Bookmark
          if (bmKey != null)
            IconButton(
              icon: Icon(bm.isBookmarked(bmKey) ? Icons.bookmark : Icons.bookmark_border),
              tooltip: bm.isBookmarked(bmKey) ? 'Buang Simpanan' : 'Simpan Doa',
              onPressed: () => bm.toggle(bmKey),
            ),
          // Counter
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
          // Page indicator dots
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
              onPageChanged: _onPageChanged,
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
            repeat: _repeat,
            onRepeatToggle: () => setState(() => _repeat = !_repeat),
            onPrev: () => _goTo(_currentIndex - 1, autoPlay: true),
            onNext: () => _goTo(_currentIndex + 1, autoPlay: true),
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

          if (!doa.autoPlay)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pause_circle_outline, color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Text('Jeda — main secara manual', style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            ),

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

          if (doa.textFile != null) ...[
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: rootBundle.loadString('assets/text/${doa.textFile}'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return Html(data: snapshot.data!);
              },
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final DoaItem doa;
  final bool repeat;
  final VoidCallback onRepeatToggle;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavBar({
    required this.currentIndex,
    required this.total,
    required this.doa,
    required this.repeat,
    required this.onRepeatToggle,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final hasAudio = doa.audioPath != null;
    final isPlaying = hasAudio && audio.isCurrentlyPlaying(doa.audioPath!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
            // Repeat toggle
            IconButton(
              icon: Icon(
                repeat ? Icons.repeat_one : Icons.repeat,
                color: repeat ? const Color(0xFF1B5E20) : Colors.grey,
              ),
              tooltip: repeat ? 'Ulang: Hidup' : 'Ulang: Mati',
              onPressed: onRepeatToggle,
            ),

            // Skip previous
            IconButton.filled(
              icon: const Icon(Icons.skip_previous),
              style: IconButton.styleFrom(
                backgroundColor: currentIndex > 0 ? const Color(0xFF1B5E20) : Colors.grey[300],
                iconSize: 20,
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => context.read<AudioProvider>().play(doa.audioPath!),
                      )
                    : const Text(
                        'Tiada audio',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
              ),
            ),

            // Skip next
            IconButton.filled(
              icon: const Icon(Icons.skip_next),
              style: IconButton.styleFrom(
                backgroundColor: currentIndex < total - 1 ? const Color(0xFF1B5E20) : Colors.grey[300],
                iconSize: 20,
              ),
              onPressed: currentIndex < total - 1 ? onNext : null,
            ),

            // Spacer to balance repeat icon
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

/// Shows 7 colored circles indicating round completion status for Tawaf/Sa'ie.
class _RoundStatusIndicator extends StatelessWidget {
  final String prefix;
  final int total;
  final ProgressProvider progressProvider;

  const _RoundStatusIndicator({
    required this.prefix,
    required this.total,
    required this.progressProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final confirmed = progressProvider.getConfirmedCount(prefix);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${prefix == 'tawaf' ? 'Tawaf' : prefix == 'tawaf_wida' ? "Tawaf Wida'" : "Sa'ie"}: $confirmed/$total selesai'),
          duration: const Duration(seconds: 2),
        ));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          final key = '${prefix}_${i + 1}';
          final status = progressProvider.getRoundStatus(key);
          final color = status == RoundStatus.confirmed
              ? Colors.white
              : status == RoundStatus.skipped
                  ? Colors.orange
                  : Colors.white30;
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: CircleAvatar(backgroundColor: color, radius: 4),
          );
        }),
      ),
    );
  }
}
