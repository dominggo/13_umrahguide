import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkProvider extends ChangeNotifier {
  static const _prefKey = 'bookmarks_v1';
  Set<String> _bookmarks = {};

  Set<String> get bookmarks => _bookmarks;

  BookmarkProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];
    _bookmarks = list.toSet();
    notifyListeners();
  }

  Future<void> toggle(String key) async {
    if (_bookmarks.contains(key)) {
      _bookmarks.remove(key);
    } else {
      _bookmarks.add(key);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKey, _bookmarks.toList());
  }

  bool isBookmarked(String key) => _bookmarks.contains(key);

  /// Build bookmark key from step id, substep id, and doa title
  static String keyFor(String stepId, String substepId, String doaTitle) =>
      '${stepId}__${substepId}__$doaTitle';
}
