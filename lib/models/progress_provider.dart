import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgressProvider extends ChangeNotifier {
  static const _autoPlayKey = 'autoPlayEnabled';

  bool _autoPlayEnabled = true;

  bool get autoPlayEnabled => _autoPlayEnabled;

  set autoPlayEnabled(bool v) {
    if (_autoPlayEnabled == v) return;
    _autoPlayEnabled = v;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_autoPlayKey, v);
    });
    notifyListeners();
  }

  ProgressProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoPlayEnabled = prefs.getBool(_autoPlayKey) ?? true;
    notifyListeners();
  }

  Future<void> clearProgress() async {
    notifyListeners();
  }
}
