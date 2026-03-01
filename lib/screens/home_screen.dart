import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/umrah_data.dart';
import '../models/umrah_step.dart';
import '../models/bookmark_provider.dart';
import '../models/progress_provider.dart';
import 'step_detail_screen.dart';
import 'guide_flow_screen.dart';
import 'search_screen.dart';
import 'makkah_map_screen.dart';
import 'journey_screen.dart';
import 'journey_history_screen.dart';
import 'doa_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  static const _tabs = [
    _MenuTab(),
    _GuideFlowTab(),
    _BookmarksTab(),
    MakkahMapScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Umrah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Cari Doa',
            onPressed: () => showSearch(context: context, delegate: UmrahSearchDelegate()),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Sejarah Umrah',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JourneyHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: _tabs[_selectedTab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) => setState(() => _selectedTab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_walk_outlined),
            selectedIcon: Icon(Icons.directions_walk),
            label: 'Panduan Aliran',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Simpan',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Peta',
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Panduan Umrah',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.mosque, size: 48, color: Color(0xFF1B5E20)),
      children: const [
        Text('Aplikasi panduan ibadah umrah lengkap dengan doa dalam gambar dan audio.'),
      ],
    );
  }
}

// ─── Menu Tab ────────────────────────────────────────────────────────────────

class _MenuTab extends StatelessWidget {
  const _MenuTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HeaderBanner()),
        // "Masuk ke Masjid" card
        const SliverToBoxAdapter(child: _JourneyStartCard()),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _StepCard(step: umrahSteps[index]),
              childCount: umrahSteps.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
          ),
        ),
      ],
    );
  }
}

class _JourneyStartCard extends StatelessWidget {
  const _JourneyStartCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        color: const Color(0xFF1B5E20),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const JourneyScreen()),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.mosque, color: Colors.white, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Masuk ke Masjid untuk Mulakan Tawaf',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Pantau perjalanan umrah anda secara langsung',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.mosque, color: Colors.white, size: 48),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat Datang',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  'Panduan Umrah',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Pilih langkah atau ikut aliran panduan',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final UmrahStep step;
  const _StepCard({required this.step});

  static const _stepColors = [
    Color(0xFF1B5E20),
    Color(0xFF0D47A1),
    Color(0xFF4A148C),
    Color(0xFF880E4F),
    Color(0xFFE65100),
    Color(0xFF006064),
    Color(0xFF37474F),
    Color(0xFF5D4037),
    Color(0xFF00695C), // Lain-lain Doa
  ];

  static const _stepIcons = [
    Icons.spa,
    Icons.location_city,
    Icons.visibility,
    Icons.rotate_right,
    Icons.hotel_class,
    Icons.directions_walk,
    Icons.content_cut,
    Icons.favorite,
    Icons.auto_stories, // Lain-lain Doa
  ];

  @override
  Widget build(BuildContext context) {
    final idx = umrahSteps.indexOf(step);
    final color = _stepColors[idx % _stepColors.length];
    final icon = _stepIcons[idx % _stepIcons.length];

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StepDetailScreen(step: step)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 80,
              color: color,
              child: Center(
                child: Icon(icon, color: Colors.white, size: 40),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${idx + 1}. ${step.title}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      step.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Guide Flow Tab ───────────────────────────────────────────────────────────

class _GuideFlowTab extends StatelessWidget {
  const _GuideFlowTab();

  @override
  Widget build(BuildContext context) {
    final prog = context.watch<ProgressProvider>();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1B5E20),
          child: const Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ikut langkah demi langkah panduan umrah anda',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),

        // Resume banner
        if (prog.hasSavedProgress)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GuideFlowScreen(
                  steps: umrahSteps,
                  initialStepIndex: prog.stepIndex,
                  initialSubStepIndex: prog.subStepIndex,
                ),
              ),
            ),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B5E20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sambung Semula',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                        Text(
                          'Langkah ${prog.stepIndex + 1}: ${umrahSteps[prog.stepIndex].title}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF1B5E20)),
                ],
              ),
            ),
          ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: umrahSteps.length,
            itemBuilder: (context, index) {
              final step = umrahSteps[index];
              final isLast = index == umrahSteps.length - 1;
              return _FlowStepTile(
                step: step,
                stepNumber: index + 1,
                isLast: isLast,
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mula Panduan Aliran'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuideFlowScreen(steps: umrahSteps, initialStepIndex: 0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlowStepTile extends StatelessWidget {
  final UmrahStep step;
  final int stepNumber;
  final bool isLast;

  const _FlowStepTile({required this.step, required this.stepNumber, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1B5E20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(step.subtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StepDetailScreen(step: step)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bookmarks Tab ────────────────────────────────────────────────────────────

class _BookmarksTab extends StatelessWidget {
  const _BookmarksTab();

  @override
  Widget build(BuildContext context) {
    final bm = context.watch<BookmarkProvider>();
    final keys = bm.bookmarks.toList();

    if (keys.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Belum ada doa yang disimpan', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text(
              'Ketuk ikon bookmark pada mana-mana doa untuk menyimpannya',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group by step name
    final grouped = <String, List<_BookmarkEntry>>{};
    for (final key in keys) {
      final parts = key.split('__');
      if (parts.length < 3) continue;
      final stepId = parts[0];
      final substepId = parts[1];
      final doaTitle = parts[2];

      // Find the matching step, substep, and doa
      for (final step in umrahSteps) {
        if (step.id != stepId) continue;
        for (final sub in step.subSteps) {
          if (sub.id != substepId) continue;
          for (int i = 0; i < sub.duas.length; i++) {
            if (sub.duas[i].title == doaTitle) {
              grouped.putIfAbsent(step.title, () => []).add(_BookmarkEntry(
                doa: sub.duas[i],
                index: i,
                siblings: sub.duas,
                substepTitle: sub.title,
                key: key,
              ));
            }
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B5E20)),
              ),
            ),
            ...entry.value.map((bEntry) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: bEntry.doa.imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              bEntry.doa.imagePath!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.menu_book, size: 36, color: Color(0xFF1B5E20)),
                            ),
                          )
                        : const Icon(Icons.menu_book, color: Color(0xFF1B5E20)),
                    title: Text(bEntry.doa.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(bEntry.substepTitle, style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark, color: Color(0xFF1B5E20)),
                      onPressed: () => bm.toggle(bEntry.key),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoaViewerScreen(
                          duas: bEntry.siblings,
                          initialIndex: bEntry.index,
                          title: bEntry.substepTitle,
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        );
      }).toList(),
    );
  }
}

class _BookmarkEntry {
  final DoaItem doa;
  final int index;
  final List<DoaItem> siblings;
  final String substepTitle;
  final String key;

  const _BookmarkEntry({
    required this.doa,
    required this.index,
    required this.siblings,
    required this.substepTitle,
    required this.key,
  });
}
