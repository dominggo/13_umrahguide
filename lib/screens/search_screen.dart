import 'package:flutter/material.dart';
import '../data/umrah_data.dart';
import '../models/umrah_step.dart';
import 'doa_viewer_screen.dart';

class UmrahSearchDelegate extends SearchDelegate<DoaItem?> {
  UmrahSearchDelegate() : super(searchFieldLabel: 'Cari doa...');

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Taip nama doa untuk mencari', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final results = _search(query);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text('"$query" tidak dijumpai', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = results[i];
        return ListTile(
          leading: r.doa.imagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    r.doa.imagePath!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.menu_book, size: 36, color: Color(0xFF1B5E20)),
                  ),
                )
              : const Icon(Icons.menu_book, color: Color(0xFF1B5E20)),
          title: Text(r.doa.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${r.stepTitle} › ${r.substepTitle}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: r.doa.audioPath != null
              ? const Icon(Icons.volume_up_outlined, size: 18, color: Color(0xFF1B5E20))
              : null,
          onTap: () {
            close(context, r.doa);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DoaViewerScreen(
                  duas: r.siblings,
                  initialIndex: r.indexInSiblings,
                  title: r.substepTitle,
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_SearchResult> _search(String q) {
    final lower = q.toLowerCase();
    final out = <_SearchResult>[];
    for (final step in umrahSteps) {
      for (final sub in step.subSteps) {
        for (int i = 0; i < sub.duas.length; i++) {
          final doa = sub.duas[i];
          if (doa.title.toLowerCase().contains(lower)) {
            out.add(_SearchResult(
              doa: doa,
              stepTitle: step.title,
              substepTitle: sub.title,
              siblings: sub.duas,
              indexInSiblings: i,
            ));
          }
        }
      }
    }
    return out;
  }
}

class _SearchResult {
  final DoaItem doa;
  final String stepTitle;
  final String substepTitle;
  final List<DoaItem> siblings;
  final int indexInSiblings;

  const _SearchResult({
    required this.doa,
    required this.stepTitle,
    required this.substepTitle,
    required this.siblings,
    required this.indexInSiblings,
  });
}
