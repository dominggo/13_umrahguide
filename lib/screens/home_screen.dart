import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/umrah_data.dart';
import '../models/umrah_step.dart';
import '../models/bookmark_provider.dart';
import 'step_detail_screen.dart';
import 'search_screen.dart';
import 'map_screen.dart';
import 'umrah_all_screen.dart';
import 'umrah_ini_screen.dart';
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
    UmrahIniScreen(),
    UmrahAllScreen(),
    MapScreen(),
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
            onPressed: () =>
                showSearch(context: context, delegate: UmrahSearchDelegate()),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Simpanan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _BookmarksScreen()),
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
            icon: _NavIcon('assets/images/custom_icons/nav_menu.png', Icons.menu_book_outlined),
            selectedIcon: _NavIcon('assets/images/custom_icons/nav_menu_active.png', Icons.menu_book),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: _NavIcon('assets/images/custom_icons/nav_umrah.png', Icons.directions_walk_outlined),
            selectedIcon: _NavIcon('assets/images/custom_icons/nav_umrah_active.png', Icons.directions_walk),
            label: 'Umrah',
          ),
          NavigationDestination(
            icon: _NavIcon('assets/images/custom_icons/nav_sejarah.png', Icons.history_outlined),
            selectedIcon: _NavIcon('assets/images/custom_icons/nav_sejarah_active.png', Icons.history),
            label: 'Sejarah',
          ),
          NavigationDestination(
            icon: _NavIcon('assets/images/custom_icons/nav_peta.png', Icons.map_outlined),
            selectedIcon: _NavIcon('assets/images/custom_icons/nav_peta_active.png', Icons.map),
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
      applicationIcon:
          const Icon(Icons.mosque, size: 48, color: Color(0xFF1B5E20)),
      children: const [
        Text(
            'Aplikasi panduan ibadah umrah lengkap dengan doa dalam gambar dan audio.'),
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
                  'Pilih menu atau klik pada tab Umrah untuk mulakan Umrah',
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
    Color(0xFF00695C),
  ];

  static const _stepIconAssets = [
    'assets/images/custom_icons/step_ihram.png',
    'assets/images/custom_icons/step_tawaf.png',
    'assets/images/custom_icons/step_solat_tawaf.png',
    'assets/images/custom_icons/step_saie.png',
    'assets/images/custom_icons/step_tahallul.png',
    'assets/images/custom_icons/step_tawaf_wida.png',
    'assets/images/custom_icons/step_lain_lain.png',
    'assets/images/custom_icons/step_panduan.png',
  ];

  static const _stepIconsFallback = [
    Icons.spa,
    Icons.rotate_right,
    Icons.hotel_class,
    Icons.directions_walk,
    Icons.content_cut,
    Icons.favorite,
    Icons.auto_stories,
    Icons.menu_book,
  ];

  @override
  Widget build(BuildContext context) {
    final idx = umrahSteps.indexOf(step);
    final color = _stepColors[idx % _stepColors.length];
    final iconAsset = _stepIconAssets[idx % _stepIconAssets.length];
    final iconFallback = _stepIconsFallback[idx % _stepIconsFallback.length];

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
                child: Image.asset(
                  iconAsset,
                  width: 40,
                  height: 40,
                  color: Colors.white,
                  errorBuilder: (_, __, ___) =>
                      Icon(iconFallback, color: Colors.white, size: 40),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '${idx + 1}. ${step.title}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

// ─── Bookmarks Screen (pushed from AppBar) ────────────────────────────────────

class _BookmarksScreen extends StatelessWidget {
  const _BookmarksScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Simpanan')),
        body: const _BookmarksTab(),
      );
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
            Text('Belum ada doa yang disimpan',
                style: TextStyle(color: Colors.grey)),
            SizedBox(height: 4),
            Text(
              'tap ikon bookmark pada mana-mana doa untuk menyimpannya',
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
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1B5E20)),
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
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.menu_book,
                                  size: 36,
                                  color: Color(0xFF1B5E20)),
                            ),
                          )
                        : const Icon(Icons.menu_book, color: Color(0xFF1B5E20)),
                    title: Text(bEntry.doa.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(bEntry.substepTitle,
                        style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon:
                          const Icon(Icons.bookmark, color: Color(0xFF1B5E20)),
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

// ─── Nav Icon with PNG fallback ───────────────────────────────────────────────

class _NavIcon extends StatelessWidget {
  final String assetPath;
  final IconData fallback;
  const _NavIcon(this.assetPath, this.fallback);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: 24,
      height: 24,
      errorBuilder: (_, __, ___) => Icon(fallback, size: 24),
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
