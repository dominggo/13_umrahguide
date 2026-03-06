import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../data/umrah_data.dart';
import '../models/umrah_step.dart';
import '../models/audio_provider.dart';
import '../models/bookmark_provider.dart';
import '../models/progress_provider.dart';
import '../models/location_provider.dart';
import '../models/journey_history_provider.dart';
import '../services/analytics_service.dart';
import 'journey_summary_screen.dart';

/// Flat entry combining a substep and one of its duas, for fullStep navigation.
typedef _FlatEntry = ({UmrahSubStep substep, DoaItem doa});

class DoaViewerScreen extends StatefulWidget {
  final List<DoaItem> duas;
  final int initialIndex;
  final String title;

  /// Step id for bookmark key building
  final String? stepId;

  /// Substep id for bookmark key building (used when fullStep is null)
  final String? substepId;

  /// When set, navigate across all substeps of this step in flat order.
  final UmrahStep? fullStep;

  /// When true, shows checkpoint navigation button; set when opened from JourneyScreen.
  final bool fromJourney;

  const DoaViewerScreen({
    super.key,
    required this.duas,
    required this.initialIndex,
    required this.title,
    this.stepId,
    this.substepId,
    this.fullStep,
    this.fromJourney = false,
  });

  @override
  State<DoaViewerScreen> createState() => _DoaViewerScreenState();
}

class _DoaViewerScreenState extends State<DoaViewerScreen> {
  // Flat list of all (substep, doa) pairs when fullStep is provided
  late final List<_FlatEntry> _flatEntries;
  // Effective duas list (flat when fullStep set, else widget.duas)
  late final List<DoaItem> _duas;

  late PageController _pageCtrl;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    if (widget.fullStep != null) {
      _flatEntries = [
        for (final sub in widget.fullStep!.subSteps)
          for (final doa in sub.duas) (substep: sub, doa: doa),
      ];
      _duas = _flatEntries.map((e) => e.doa).toList();
    } else {
      _flatEntries = [];
      _duas = widget.duas;
    }

    _currentIndex =
        widget.initialIndex.clamp(0, _duas.isEmpty ? 0 : _duas.length - 1);
    _pageCtrl = PageController(initialPage: _currentIndex);

    // Record checkpoint start for the initial doa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeRecordCheckpointStart(_currentIndex);
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Derived helpers ──────────────────────────────────────────────────────

  String? get _currentStepId => widget.fullStep?.id ?? widget.stepId;

  String? get _currentSubstepId {
    if (widget.fullStep != null && _flatEntries.isNotEmpty) {
      return _flatEntries[_currentIndex].substep.id;
    }
    return widget.substepId;
  }

  String get _currentSubstepTitle {
    if (widget.fullStep != null && _flatEntries.isNotEmpty) {
      return _flatEntries[_currentIndex].substep.title;
    }
    return widget.title;
  }

  DoaItem get _currentDoa => _duas[_currentIndex];

  String? get _derivedRoundPrefix {
    final subId = _currentSubstepId;
    if (subId == null) return null;

    if (subId.startsWith('tawaf_') && !subId.startsWith('tawaf_wida_')) {
      final n = int.tryParse(subId.split('_').last);
      if (n != null && n >= 1 && n <= 7) return 'tawaf';
    }
    if (subId.startsWith('saie_') && !subId.contains('doa')) {
      final n = int.tryParse(subId.split('_').last);
      if (n != null && n >= 1 && n <= 7) return 'saie';
    }
    return null;
  }

  int? get _derivedRoundNum {
    final subId = _currentSubstepId;
    if (subId == null) return null;
    return int.tryParse(subId.split('_').last);
  }

  bool get _isRoundSubstep => _derivedRoundPrefix != null;

  String _buildAppBarTitle() {
    final prefix = _derivedRoundPrefix;
    final roundNum = _derivedRoundNum;
    if (prefix == 'saie' && roundNum != null) {
      return '${widget.fullStep?.title ?? widget.title} $roundNum/7';
    }
    return widget.fullStep != null ? _currentSubstepTitle : widget.title;
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _duas.length) return;
    await _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int i) {
    setState(() => _currentIndex = i);
    context.read<AudioProvider>().stop();
    _maybeRecordCheckpointStart(i);
  }

  /// Records checkPointStart for doa at [index] if journey is active.
  void _maybeRecordCheckpointStart(int index) {
    if (index < 0 || index >= _duas.length) return;
    final doa = _duas[index];
    if (doa.checkPointStart == null) return;
    final loc = context.read<LocationProvider>();
    if (!loc.isJourneyActive) return;
    final substepTitle = widget.fullStep != null && _flatEntries.isNotEmpty
        ? _flatEntries[index].substep.title
        : widget.title;
    loc.recordCheckpointStart(doa.checkPointStart!, doa.checkPointName ?? substepTitle);
  }

  // ── Checkpoint end button handler ────────────────────────────────────────

  bool get _showCheckpointEndButton {
    if (!widget.fromJourney) return false;
    if (_duas.isEmpty) return false;
    return _currentDoa.checkPointEnd != null;
  }

  /// Tapping the checkpoint-end button: show confirmation dialog, then record end
  /// and navigate to next section (substep with checkPointStart == num+1).
  Future<void> _handleCheckpointEnd() async {
    final doa = _currentDoa;
    final endNum = doa.checkPointEnd!;
    final loc = context.read<LocationProvider>();
    if (!loc.isJourneyActive) return;

    final nextLabel = doa.nextLabel ?? '';
    final isFinish = nextLabel == 'Selesai Umrah';

    if (isFinish) {
      await loc.recordCheckpointEnd(endNum);
      if (!mounted) return;
      await _confirmFinalizeJourney(context, loc);
      return;
    }

    // Confirm dialog
    final substepName = _currentSubstepTitle;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Selesai $substepName?'),
        content: Text('Adakah anda telah selesai $substepName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tidak')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await loc.recordCheckpointEnd(endNum);
    AnalyticsService.logCheckpointCompleted(
        checkpointNum: endNum, name: substepName);

    // Navigate: find doa with checkPointStart == endNum + 1 in fullStep or umrahSteps
    final nextNum = endNum + 1;
    if (widget.fullStep != null) {
      // Try to find within current fullStep
      for (int fi = 0; fi < _flatEntries.length; fi++) {
        if (_flatEntries[fi].doa.checkPointStart == nextNum) {
          await _goTo(fi);
          return;
        }
      }
    }

    // Search across all umrahSteps
    for (final step in umrahSteps) {
      int flatOffset = 0;
      for (final sub in step.subSteps) {
        for (int di = 0; di < sub.duas.length; di++) {
          if (sub.duas[di].checkPointStart == nextNum) {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoaViewerScreen(
                  duas: const [],
                  initialIndex: flatOffset + di,
                  title: step.title,
                  stepId: step.id,
                  fullStep: step,
                  fromJourney: true,
                ),
              ),
            );
            return;
          }
          flatOffset++;
        }
      }
    }
  }

  Future<void> _confirmFinalizeJourney(
      BuildContext ctx, LocationProvider loc) async {
    final history = ctx.read<JourneyHistoryProvider>();
    final prog = ctx.read<ProgressProvider>();

    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Tamatkan Umrah?'),
        content: const Text('Tamatkan Umrah? Rekod lengkap akan disimpan.'),
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

    if (confirm != true) return;

    // 1. Finalize journey
    final record = await loc.finalizeJourney();

    // 2. Save history WITH error handling
    try {
      await history.addOrUpdateJourney(record);
      debugPrint('✓ History saved: ${record.id}');
    } catch (e) {
      debugPrint('✗ History save failed: $e');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Gagal simpan rekod: $e')),
        );
      }
      return; // Stop here if save failed
    }

    // 3. Clear progress only after successful save
    await prog.clearProgress();

    // 4. Navigate
    if (ctx.mounted) {
      Navigator.of(ctx).pushReplacement(
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

  @override
  Widget build(BuildContext context) {
    final total = _duas.length;
    final prog = context.watch<ProgressProvider>();
    final bm = context.watch<BookmarkProvider>();
    final loc = context.watch<LocationProvider>();

    final currentDoa = total > 0 ? _duas[_currentIndex] : null;
    final curStep = _currentStepId;
    final curSub = _currentSubstepId;
    final bmKey = curStep != null && curSub != null && currentDoa != null
        ? BookmarkProvider.keyFor(curStep, curSub, currentDoa.title)
        : null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 88,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Utama',
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
        title: Text(_buildAppBarTitle()),
        actions: [
          // Round indicator for Tawaf/Sa'ie
          if (widget.fromJourney && _isRoundSubstep)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _RoundStatusIndicator(
                prefix: _derivedRoundPrefix!,
                total: 7,
                progressProvider: prog,
                locationProvider: loc,
              ),
            ),
          // Bookmark
          if (bmKey != null)
            IconButton(
              icon: Icon(bm.isBookmarked(bmKey)
                  ? Icons.bookmark
                  : Icons.bookmark_border),
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
      body: total == 0
          ? const Center(child: Text('Tiada doa'))
          : Column(
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                '${_currentIndex + 1}/$total',
                                style:
                                    const TextStyle(color: Color(0xFF1B5E20)),
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
                                    : const Color(0xFF1B5E20)
                                        .withValues(alpha: 0.3),
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
                      return _DoaPage(doa: _duas[index]);
                    },
                  ),
                ),

                // Navigation bar + optional action row
                SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavBar(
                        canGoPrev: _currentIndex > 0,
                        canGoNext: _currentIndex < _duas.length - 1 &&
                            !_showCheckpointEndButton,
                        doa: currentDoa!,
                        onPrev: () => _goTo(_currentIndex - 1),
                        onNext: () => _goTo(_currentIndex + 1),
                      ),
                      // Action row
                      Consumer<LocationProvider>(
                        builder: (ctx, loc, _) {
                          final showCpEnd =
                              _showCheckpointEndButton && loc.isJourneyActive;
                          final showStart = currentDoa.checkPointStart == 1 &&
                              !loc.isJourneyActive;

                          if (!showCpEnd && !showStart) {
                            return const SizedBox.shrink();
                          }

                          return Container(
                            color: Colors.white,
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                            child: Row(
                              children: [
                                if (showStart)
                                  Expanded(
                                    child: FilledButton.icon(
                                      icon: const Icon(Icons.play_arrow,
                                          size: 16),
                                      label: const Text('Mulakan Umrah',
                                          style: TextStyle(fontSize: 12)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF1B5E20),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () async {
                                        if (!loc.gpsAvailable) {
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'GPS tidak tersedia. Perjalanan direkod tanpa GPS.'),
                                          ));
                                        }
                                        await loc.startJourney();
                                        if (mounted) {
                                          _maybeRecordCheckpointStart(
                                              _currentIndex);
                                        }
                                      },
                                    ),
                                  ),
                                if (showCpEnd)
                                  Expanded(
                                    child:
                                        _buildCheckpointEndButton(currentDoa),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCheckpointEndButton(DoaItem doa) {
    final nextLabel = doa.nextLabel ?? '';
    final isFinish = nextLabel == 'Selesai Umrah';

    if (isFinish) {
      return FilledButton.icon(
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label: const Text('Tamatkan Umrah', style: TextStyle(fontSize: 12)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green[700],
          visualDensity: VisualDensity.compact,
        ),
        onPressed: _handleCheckpointEnd,
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(Icons.arrow_forward, size: 16),
      label: Text(
        nextLabel.isNotEmpty ? 'Mulakan $nextLabel' : 'Seterusnya',
        style: const TextStyle(fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
      onPressed: _handleCheckpointEnd,
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
                  Icon(Icons.pause_circle_outline,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 6),
                  Text('Jeda — main secara manual',
                      style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            ),
          if (doa.imagePath != null)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
                        Icon(Icons.image_not_supported_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Gambar tidak dijumpai',
                            style: TextStyle(color: Colors.grey)),
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
                child:
                    Icon(Icons.menu_book, size: 64, color: Color(0xFF1B5E20)),
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
              child: Text(doa.description!,
                  style: const TextStyle(fontSize: 14, height: 1.6)),
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
  final bool canGoPrev;
  final bool canGoNext;
  final DoaItem doa;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _NavBar({
    required this.canGoPrev,
    required this.canGoNext,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          // Skip previous
          IconButton.filled(
            icon: const Icon(Icons.skip_previous),
            style: IconButton.styleFrom(
              backgroundColor:
                  canGoPrev ? const Color(0xFF1B5E20) : Colors.grey[300],
              iconSize: 20,
            ),
            onPressed: canGoPrev ? onPrev : null,
          ),

          // Audio play button (center)
          Expanded(
            child: Center(
              child: hasAudio
                  ? FilledButton.icon(
                      icon: Icon(isPlaying ? Icons.pause : Icons.volume_up),
                      label: Text(isPlaying ? 'Berhenti' : 'Dengar Doa'),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isPlaying ? Colors.orange : const Color(0xFF1B5E20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onPressed: () =>
                          context.read<AudioProvider>().play(doa.audioPath!),
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
              backgroundColor:
                  canGoNext ? const Color(0xFF1B5E20) : Colors.grey[300],
              iconSize: 20,
            ),
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

/// Shows 7 colored circles indicating round completion status for Tawaf/Sa'ie.
class _RoundStatusIndicator extends StatelessWidget {
  final String prefix;
  final int total;
  final ProgressProvider progressProvider;
  final LocationProvider locationProvider;

  // Checkpoint numbers for tawaf rounds 1–7 (CP2–CP8)
  static const _tawafCPs = [2, 3, 4, 5, 6, 7, 8];
  // Checkpoint numbers for saie rounds 1–7 (CP11–CP17)
  static const _saieCPs = [11, 12, 13, 14, 15, 16, 17];

  const _RoundStatusIndicator({
    required this.prefix,
    required this.total,
    required this.progressProvider,
    required this.locationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        int done;
        if (prefix == 'tawaf') {
          done = _tawafCPs.where((n) => locationProvider.isCheckpointCompleted(n)).length;
        } else if (prefix == 'saie') {
          done = _saieCPs.where((n) => locationProvider.isCheckpointCompleted(n)).length;
        } else {
          done = progressProvider.getConfirmedCount(prefix);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${prefix == 'tawaf' ? 'Tawaf' : prefix == 'tawaf_wida' ? "Tawaf Wida'" : "Sa'ie"}: $done/$total selesai'),
          duration: const Duration(seconds: 2),
        ));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(total, (i) {
          Color color;
          if (prefix == 'tawaf') {
            final cp = _tawafCPs[i];
            color = locationProvider.isCheckpointCompleted(cp)
                ? Colors.white
                : locationProvider.isCheckpointStarted(cp)
                    ? Colors.orange
                    : Colors.white30;
          } else if (prefix == 'saie') {
            final cp = _saieCPs[i];
            color = locationProvider.isCheckpointCompleted(cp)
                ? Colors.white
                : locationProvider.isCheckpointStarted(cp)
                    ? Colors.orange
                    : Colors.white30;
          } else {
            // tawaf_wida — no checkpoints, fall back to ProgressProvider
            final status = progressProvider.getRoundStatus('${prefix}_${i + 1}');
            color = status == RoundStatus.confirmed
                ? Colors.white
                : status == RoundStatus.skipped
                    ? Colors.orange
                    : Colors.white30;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 3),
            child: CircleAvatar(backgroundColor: color, radius: 4),
          );
        }),
      ),
    );
  }
}
