import 'package:flutter/material.dart';
import '../models/umrah_step.dart';
import 'doa_viewer_screen.dart';

/// Full guided flow - walks user step by step through all Umrah stages
class GuideFlowScreen extends StatefulWidget {
  final List<UmrahStep> steps;
  final int initialStepIndex;

  const GuideFlowScreen({
    super.key,
    required this.steps,
    required this.initialStepIndex,
  });

  @override
  State<GuideFlowScreen> createState() => _GuideFlowScreenState();
}

class _GuideFlowScreenState extends State<GuideFlowScreen> {
  late int _stepIndex;
  late int _subStepIndex;

  @override
  void initState() {
    super.initState();
    _stepIndex = widget.initialStepIndex;
    _subStepIndex = 0;
  }

  UmrahStep get _currentStep => widget.steps[_stepIndex];
  UmrahSubStep get _currentSubStep => _currentStep.subSteps[_subStepIndex];

  bool get _hasPrev => _stepIndex > 0 || _subStepIndex > 0;
  bool get _hasNext =>
      _subStepIndex < _currentStep.subSteps.length - 1 ||
      _stepIndex < widget.steps.length - 1;

  void _goNext() {
    setState(() {
      if (_subStepIndex < _currentStep.subSteps.length - 1) {
        _subStepIndex++;
      } else if (_stepIndex < widget.steps.length - 1) {
        _stepIndex++;
        _subStepIndex = 0;
      }
    });
  }

  void _goPrev() {
    setState(() {
      if (_subStepIndex > 0) {
        _subStepIndex--;
      } else if (_stepIndex > 0) {
        _stepIndex--;
        _subStepIndex = widget.steps[_stepIndex].subSteps.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.steps.length;
    final progress = (_stepIndex + (_subStepIndex + 1) / _currentStep.subSteps.length) / totalSteps;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          // Step & substep header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Langkah ${_stepIndex + 1}/$totalSteps',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentSubStep.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Doa list for current substep
          Expanded(
            child: _currentSubStep.duas.isEmpty
                ? const Center(child: Text('Tiada doa untuk bahagian ini'))
                : _currentSubStep.duas.length == 1
                    ? _SingleDoaView(doa: _currentSubStep.duas.first)
                    : _DoaListView(
                        duas: _currentSubStep.duas,
                        subStepTitle: _currentSubStep.title,
                      ),
          ),

          // Navigation
          _FlowNavBar(
            hasPrev: _hasPrev,
            hasNext: _hasNext,
            onPrev: _goPrev,
            onNext: _goNext,
            stepTitle: _currentStep.title,
            isLastStep: !_hasNext,
          ),
        ],
      ),
    );
  }
}

class _SingleDoaView extends StatelessWidget {
  final DoaItem doa;
  const _SingleDoaView({required this.doa});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoaViewerScreen(duas: [doa], initialIndex: 0, title: doa.title),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (doa.imagePath != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Image.asset(
                      doa.imagePath!,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[100],
                        child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Ketuk untuk besarkan', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
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
            const SizedBox(height: 12),
            Text(
              doa.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoaListView extends StatelessWidget {
  final List<DoaItem> duas;
  final String subStepTitle;

  const _DoaListView({required this.duas, required this.subStepTitle});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: duas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final doa = duas[i];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: doa.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      doa.imagePath!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.menu_book, size: 36, color: Color(0xFF1B5E20)),
                    ),
                  )
                : const Icon(Icons.menu_book, size: 36, color: Color(0xFF1B5E20)),
            title: Text(doa.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoaViewerScreen(duas: duas, initialIndex: i, title: subStepTitle),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlowNavBar extends StatelessWidget {
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final String stepTitle;
  final bool isLastStep;

  const _FlowNavBar({
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
    required this.stepTitle,
    required this.isLastStep,
  });

  @override
  Widget build(BuildContext context) {
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
            IconButton.filled(
              icon: const Icon(Icons.arrow_back_ios_new),
              style: IconButton.styleFrom(
                backgroundColor: hasPrev ? const Color(0xFF1B5E20) : Colors.grey[300],
              ),
              onPressed: hasPrev ? onPrev : null,
            ),
            Expanded(
              child: Center(
                child: isLastStep
                    ? const Text('Tahniah! Umrah Selesai 🕌', style: TextStyle(fontWeight: FontWeight.bold))
                    : const Text('Seterusnya', style: TextStyle(color: Colors.grey)),
              ),
            ),
            if (!isLastStep)
              IconButton.filled(
                icon: const Icon(Icons.arrow_forward_ios),
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                onPressed: onNext,
              )
            else
              IconButton.filled(
                icon: const Icon(Icons.check),
                style: IconButton.styleFrom(backgroundColor: Colors.amber[700]),
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              ),
          ],
        ),
      ),
    );
  }
}
