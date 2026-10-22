import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../models/umrah_step.dart';
import '../models/audio_provider.dart';
import '../models/bookmark_provider.dart';
import '../models/location_provider.dart';
import '../models/journey_models.dart';
import '../models/progress_provider.dart';
import '../services/analytics_service.dart';
import '../utils/format.dart';
import 'home_screen.dart';
import 'journey_actions.dart';

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

  late final AudioProvider _audio;
  StreamSubscription<void>? _trackSub;

  /// Set while auto-play turns the page, so the page change keeps the audio.
  bool _autoAdvancing = false;

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

    _audio = context.read<AudioProvider>();
    _trackSub = _audio.onTrackComplete.listen((_) => _onTrackComplete());

    // Record checkpoint start for the initial doa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeRecordCheckpointStart(_currentIndex);
    });
  }

  @override
  void dispose() {
    _trackSub?.cancel();
    _audio.stop();
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

    if (subId.startsWith('tawaf_wida_')) {
      final n = int.tryParse(subId.split('_').last);
      if (n != null && n >= 1 && n <= 7) return 'tawaf_wida';
    } else if (subId.startsWith('tawaf_')) {
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
    if (!_autoAdvancing) _audio.stop();
    _maybeRecordCheckpointStart(i);
  }

  // ── Auto-play ────────────────────────────────────────────────────────────

  /// When a doa's audio ends, turn to the next doa and play it, as long as
  /// auto-play is on and the next doa is part of the same auto-play group.
  /// A doa with autoPlay: false is a break-point the user starts by hand, and
  /// a checkpoint end waits for the user to confirm.
  Future<void> _onTrackComplete() async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
    if (!context.read<ProgressProvider>().autoPlayEnabled) return;
    if (_duas.isEmpty || _showCheckpointEndButton) return;
    final next = _currentIndex + 1;
    if (next >= _duas.length) return;
    final doa = _duas[next];
    if (!doa.autoPlay || doa.audioPath == null) return;
    _autoAdvancing = true;
    try {
      await _goTo(next);
    } finally {
      _autoAdvancing = false;
    }
    if (mounted) _audio.play(doa.audioPath!);
  }

  void _toggleAutoPlay() {
    final progress = context.read<ProgressProvider>();
    progress.autoPlayEnabled = !progress.autoPlayEnabled;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(progress.autoPlayEnabled
            ? 'Main automatik: Hidup — doa seterusnya dimainkan sendiri'
            : 'Main automatik: Mati'),
        duration: const Duration(seconds: 2),
      ));
  }

  // ── Checkpoints ──────────────────────────────────────────────────────────

  /// Records checkPointStart for doa at [index] if journey is active.
  /// Only from the journey flow: the Menu tab has no end button, so a start
  /// recorded there could never be closed.
  void _maybeRecordCheckpointStart(int index) {
    if (!widget.fromJourney) return;
    if (index < 0 || index >= _duas.length) return;
    final doa = _duas[index];
    if (doa.checkPointStart == null) return;
    final loc = context.read<LocationProvider>();
    if (!loc.isJourneyActive) return;
    final substepTitle = widget.fullStep != null && _flatEntries.isNotEmpty
        ? _flatEntries[index].substep.title
        : widget.title;
    loc.recordCheckpointStart(
        doa.checkPointStart!, doa.checkPointName ?? substepTitle);
  }

  bool get _showCheckpointEndButton {
    if (!widget.fromJourney) return false;
    if (_duas.isEmpty) return false;
    final endNum = _currentDoa.checkPointEnd;
    if (endNum == null) return false;
    // Only checkpoints of the active session's kind can be ended here
    return context.read<LocationProvider>().journeyKind.ownsCheckpoint(endNum);
  }

  /// Tapping the checkpoint-end button: show confirmation dialog, then record end
  /// and navigate to next section (substep with checkPointStart == num+1).
  Future<void> _handleCheckpointEnd() async {
    final endNum = _currentDoa.checkPointEnd!;
    final substepName = _currentSubstepTitle;
    final loc = context.read<LocationProvider>();
    if (!loc.isJourneyActive) return;

    if (endNum == loc.journeyKind.lastCp) {
      // The last checkpoint ends only once the user confirms finishing.
      await finishJourney(context, beforeFinalize: () async {
        await loc.recordCheckpointEnd(endNum);
        AnalyticsService.logCheckpointCompleted(
            checkpointNum: endNum, name: substepName);
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Selesai $substepName?'),
        content: Text('Adakah anda telah selesai $substepName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await loc.recordCheckpointEnd(endNum);
    AnalyticsService.logCheckpointCompleted(
        checkpointNum: endNum, name: substepName);

    // Next section: within this step if it's here, else open its step.
    final nextNum = endNum + 1;
    for (int fi = 0; fi < _flatEntries.length; fi++) {
      if (_flatEntries[fi].doa.checkPointStart == nextNum) {
        await _goTo(fi);
        return;
      }
    }
    if (mounted) openCheckpoint(context, nextNum);
  }

  Future<void> _startFromHere(JourneyKind kind) async {
    await startJourney(context, kind: kind, openFirstCheckpoint: false);
    if (mounted) _maybeRecordCheckpointStart(_currentIndex);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final total = _duas.length;
    final bm = context.watch<BookmarkProvider>();
    final autoPlay =
        context.select<ProgressProvider, bool>((p) => p.autoPlayEnabled);
    // Only these two values matter here; GPS fixes don't rebuild the page.
    final journeyActive =
        context.select<LocationProvider, bool>((l) => l.isJourneyActive);
    context.select<LocationProvider, JourneyKind>((l) => l.journeyKind);

    final currentDoa = total > 0 ? _duas[_currentIndex] : null;
    final curStep = _currentStepId;
    final curSub = _currentSubstepId;
    final bmKey = curStep != null && curSub != null && currentDoa != null
        ? BookmarkProvider.keyFor(curStep, curSub, currentDoa.title)
        : null;
    final anyAudio = _duas.any((d) => d.audioPath != null);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Kembali',
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
              child: Consumer<LocationProvider>(
                builder: (_, loc, __) => _RoundStatusIndicator(
                  prefix: _derivedRoundPrefix!,
                  locationProvider: loc,
                ),
              ),
            ),
          if (anyAudio)
            IconButton(
              icon: Icon(
                  autoPlay ? Icons.playlist_play : Icons.playlist_remove),
              tooltip: autoPlay ? 'Main automatik: Hidup' : 'Main automatik: Mati',
              onPressed: _toggleAutoPlay,
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
        ],
      ),
      body: total == 0
          ? const Center(child: Text('Tiada doa'))
          : Column(
              children: [
                _PageIndicator(index: _currentIndex, total: total),

                // Doa pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    itemCount: total,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) => _DoaPage(doa: _duas[index]),
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
                      _buildActionRow(currentDoa, journeyActive),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionRow(DoaItem currentDoa, bool journeyActive) {
    final showCpEnd = _showCheckpointEndButton && journeyActive;
    final startKind = switch (currentDoa.checkPointStart) {
      1 => JourneyKind.umrah,
      18 => JourneyKind.wida,
      _ => null,
    };
    final showStart = widget.fromJourney && startKind != null && !journeyActive;
    // Menu flow records nothing, so point to the Umrah tab
    final showGoToUmrah = !widget.fromJourney && startKind != null;

    if (!showCpEnd && !showStart && !showGoToUmrah) {
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
                icon: const Icon(Icons.play_arrow, size: 16),
                label: Text(
                    startKind == JourneyKind.wida
                        ? "Mulakan Tawaf Wida'"
                        : 'Mulakan Umrah',
                    style: const TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _startFromHere(startKind),
              ),
            ),
          if (showGoToUmrah)
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.directions_walk, size: 16),
                label: Text(
                    journeyActive
                        ? 'Sambung di tab Umrah'
                        : startKind == JourneyKind.wida
                            ? "Mulakan Tawaf Wida'? Tekan di sini"
                            : 'Mulakan Umrah? Tekan di sini',
                    style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryGreen,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  HomeScreen.tabRequest.value = HomeScreen.umrahTab;
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),
            ),
          if (showCpEnd)
            Expanded(child: _buildCheckpointEndButton(currentDoa)),
        ],
      ),
    );
  }

  Widget _buildCheckpointEndButton(DoaItem doa) {
    final nextLabel = doa.nextLabel ?? '';
    final kind = context.read<LocationProvider>().journeyKind;
    final isFinish = doa.checkPointEnd == kind.lastCp;

    if (isFinish) {
      return FilledButton.icon(
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label: Text(
            kind == JourneyKind.wida ? "Tamatkan Tawaf Wida'" : 'Tamatkan Umrah',
            style: const TextStyle(fontSize: 12)),
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

/// Dots for short lists (≤10) plus an "n / total" counter.
class _PageIndicator extends StatelessWidget {
  final int index;
  final int total;
  const _PageIndicator({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: kPrimaryGreen.withValues(alpha: 0.08),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (total > 1 && total <= 10)
            for (int i = 0; i < total; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == index
                      ? kPrimaryGreen
                      : kPrimaryGreen.withValues(alpha: 0.3),
                ),
              ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text('${index + 1} / $total',
                style: const TextStyle(color: kPrimaryGreen, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _DoaPage extends StatefulWidget {
  final DoaItem doa;
  const _DoaPage({required this.doa});

  @override
  State<_DoaPage> createState() => _DoaPageState();
}

class _DoaPageState extends State<_DoaPage> {
  /// Loaded HTML guides, shared across pages and viewers.
  static final Map<String, Future<String>> _textCache = {};

  Future<String>? _text;

  @override
  void initState() {
    super.initState();
    final file = widget.doa.textFile;
    if (file != null) {
      _text = _textCache.putIfAbsent(
          file, () => rootBundle.loadString('assets/text/$file'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final doa = widget.doa;
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
              color: kPrimaryGreen,
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
                color: kPrimaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.menu_book, size: 64, color: kPrimaryGreen),
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
          if (_text != null) ...[
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: _text,
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
            tooltip: 'Sebelum',
            style: IconButton.styleFrom(
              backgroundColor: canGoPrev ? kPrimaryGreen : Colors.grey[300],
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
                            isPlaying ? Colors.orange : kPrimaryGreen,
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
            tooltip: 'Seterusnya',
            style: IconButton.styleFrom(
              backgroundColor: canGoNext ? kPrimaryGreen : Colors.grey[300],
              iconSize: 20,
            ),
            onPressed: canGoNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

/// Shows 7 circles indicating round completion status for Tawaf, Sa'ie and
/// Tawaf Wida'. Status comes from the journey checkpoints of each round.
class _RoundStatusIndicator extends StatelessWidget {
  final String prefix;
  final LocationProvider locationProvider;

  // Checkpoint numbers for rounds 1–7 of each activity
  static const _tawafCPs = [2, 3, 4, 5, 6, 7, 8];
  static const _saieCPs = [10, 11, 12, 13, 14, 15, 16];
  static const _widaCPs = [18, 19, 20, 21, 22, 23, 24];

  const _RoundStatusIndicator({
    required this.prefix,
    required this.locationProvider,
  });

  List<int> get _cps => switch (prefix) {
        'tawaf' => _tawafCPs,
        'tawaf_wida' => _widaCPs,
        _ => _saieCPs,
      };

  String get _label => switch (prefix) {
        'tawaf' => 'Tawaf',
        'tawaf_wida' => "Tawaf Wida'",
        _ => "Sa'ie",
      };

  @override
  Widget build(BuildContext context) {
    final cps = _cps;
    return GestureDetector(
      onTap: () {
        final done =
            cps.where((n) => locationProvider.isCheckpointCompleted(n)).length;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$_label: $done/${cps.length} selesai'),
          duration: const Duration(seconds: 2),
        ));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final cp in cps)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: CircleAvatar(
                backgroundColor: locationProvider.isCheckpointCompleted(cp)
                    ? Colors.white
                    : locationProvider.isCheckpointStarted(cp)
                        ? Colors.orange
                        : Colors.white30,
                radius: 4,
              ),
            ),
        ],
      ),
    );
  }
}
