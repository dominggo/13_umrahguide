import 'package:flutter/material.dart';
import '../data/umrah_data.dart';
import '../models/umrah_step.dart';
import 'step_detail_screen.dart';
import 'guide_flow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panduan Umrah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang',
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: _selectedTab == 0 ? const _MenuTab() : const _GuideFlowTab(),
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

class _MenuTab extends StatelessWidget {
  const _MenuTab();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _HeaderBanner(),
        ),
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
      child: Row(
        children: [
          const Icon(Icons.mosque, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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

class _GuideFlowTab extends StatelessWidget {
  const _GuideFlowTab();

  @override
  Widget build(BuildContext context) {
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
          // Timeline column
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
                      color: const Color(0xFF1B5E20).withOpacity(0.3),
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
