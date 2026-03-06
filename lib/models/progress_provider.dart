import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status of a Tawaf/Sa'ie round
enum RoundStatus { pending, confirmed, skipped }

class ProgressProvider extends ChangeNotifier {
  static const _roundsKey = 'rounds_v1';
  static const _autoPlayKey = 'autoPlayEnabled';

  bool _autoPlayEnabled = true;

  /// Round tracking: key is substep id (e.g. "tawaf_wida_1"), value is status
  Map<String, RoundStatus> _rounds = {};

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

    final roundsJson = prefs.getString(_roundsKey);
    if (roundsJson != null) {
      final map = jsonDecode(roundsJson) as Map<String, dynamic>;
      _rounds = map.map((k, v) => MapEntry(k, _statusFromString(v as String)));
    }
    notifyListeners();
  }

  Future<void> clearProgress() async {
    notifyListeners();
  }

  // ── Round tracking ────────────────────────────────────────────────────────

  RoundStatus getRoundStatus(String substepId) =>
      _rounds[substepId] ?? RoundStatus.pending;

  /// Guard against 'tawaf' matching 'tawaf_wida_*' keys.
  bool _matchesPrefix(String key, String prefix) {
    if (!key.startsWith(prefix)) return false;
    if (prefix == 'tawaf' && key.startsWith('tawaf_wida_')) return false;
    return true;
  }

  /// How many confirmed rounds exist for a given prefix
  int getConfirmedCount(String prefix) =>
      _rounds.entries
          .where((e) => _matchesPrefix(e.key, prefix) && e.value == RoundStatus.confirmed)
          .length;

  static RoundStatus _statusFromString(String s) {
    switch (s) {
      case 'confirmed': return RoundStatus.confirmed;
      case 'skipped': return RoundStatus.skipped;
      default: return RoundStatus.pending;
    }
  }
}
