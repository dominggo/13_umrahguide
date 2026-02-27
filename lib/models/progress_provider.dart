import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Status of a Tawaf/Sa'ie round
enum RoundStatus { pending, confirmed, skipped }

class ProgressProvider extends ChangeNotifier {
  static const _stepKey = 'progress_step';
  static const _subKey = 'progress_sub';
  static const _roundsKey = 'rounds_v1';

  int _stepIndex = 0;
  int _subStepIndex = 0;
  bool _hasSaved = false;

  /// Round tracking: key is substep id (e.g. "tawaf_1"), value is status string
  Map<String, RoundStatus> _rounds = {};

  int get stepIndex => _stepIndex;
  int get subStepIndex => _subStepIndex;
  bool get hasSavedProgress => _hasSaved;

  ProgressProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _stepIndex = prefs.getInt(_stepKey) ?? 0;
    _subStepIndex = prefs.getInt(_subKey) ?? 0;
    _hasSaved = prefs.containsKey(_stepKey);

    final roundsJson = prefs.getString(_roundsKey);
    if (roundsJson != null) {
      final map = jsonDecode(roundsJson) as Map<String, dynamic>;
      _rounds = map.map((k, v) => MapEntry(k, _statusFromString(v as String)));
    }
    notifyListeners();
  }

  Future<void> saveProgress(int step, int sub) async {
    _stepIndex = step;
    _subStepIndex = sub;
    _hasSaved = true;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepKey, step);
    await prefs.setInt(_subKey, sub);
  }

  Future<void> clearProgress() async {
    _stepIndex = 0;
    _subStepIndex = 0;
    _hasSaved = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_stepKey);
    await prefs.remove(_subKey);
  }

  // ── Round tracking ────────────────────────────────────────────────────────

  Future<void> setRoundStatus(String substepId, RoundStatus status) async {
    _rounds[substepId] = status;
    notifyListeners();
    await _saveRounds();
  }

  Future<void> confirmRound(String substepId) => setRoundStatus(substepId, RoundStatus.confirmed);
  Future<void> skipRound(String substepId) => setRoundStatus(substepId, RoundStatus.skipped);

  RoundStatus getRoundStatus(String substepId) =>
      _rounds[substepId] ?? RoundStatus.pending;

  bool isRoundComplete(String substepId) =>
      _rounds[substepId] == RoundStatus.confirmed;

  /// How many confirmed rounds exist for a given prefix (e.g. "tawaf" or "saie")
  int getConfirmedCount(String prefix) =>
      _rounds.entries.where((e) => e.key.startsWith(prefix) && e.value == RoundStatus.confirmed).length;

  /// Whether any rounds with this prefix are skipped
  bool hasSkippedRounds(String prefix) =>
      _rounds.entries.any((e) => e.key.startsWith(prefix) && e.value == RoundStatus.skipped);

  Future<void> resetRounds(String prefix) async {
    _rounds.removeWhere((k, v) => k.startsWith(prefix));
    notifyListeners();
    await _saveRounds();
  }

  Future<void> _saveRounds() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _rounds.map((k, v) => MapEntry(k, _statusToString(v)));
    await prefs.setString(_roundsKey, jsonEncode(map));
  }

  static String _statusToString(RoundStatus s) {
    switch (s) {
      case RoundStatus.confirmed: return 'confirmed';
      case RoundStatus.skipped: return 'skipped';
      case RoundStatus.pending: return 'pending';
    }
  }

  static RoundStatus _statusFromString(String s) {
    switch (s) {
      case 'confirmed': return RoundStatus.confirmed;
      case 'skipped': return RoundStatus.skipped;
      default: return RoundStatus.pending;
    }
  }
}
