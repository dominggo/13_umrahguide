import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'journey_record.dart';

class JourneyHistoryProvider extends ChangeNotifier {
  List<UmrahJourneyRecord> _journeys = [];
  String? _errorMsg;

  List<UmrahJourneyRecord> get journeys {
    final sorted = List.of(_journeys)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    return List.unmodifiable(sorted);
  }

  int get totalUmrahCount => _journeys.length;
  String? get errorMsg => _errorMsg;

  JourneyHistoryProvider() {
    _load();
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/umrah_history.json');
  }

  Future<void> _load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        _journeys = [];
        _errorMsg = null;
        return;
      }
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _journeys = list
          .map((e) => UmrahJourneyRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      _errorMsg = null;
      notifyListeners();
      await migrateIfNeeded();
    } catch (e) {
      _errorMsg = 'Error loading journeys: $e';
      notifyListeners();
    }
  }

  Future<void> _save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/umrah_history.json');

      final jsonList = _journeys.map((j) => j.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      await file.writeAsString(jsonString);

      // DEBUG: Verify immediately
      debugPrint('✓ Saved ${jsonString.length} chars to ${file.path}');
      debugPrint('✓ Journeys in memory: ${_journeys.length}');
    } catch (e, stack) {
      debugPrint('✗ Save error: $e');
      debugPrint(stack.toString());
      rethrow; // Important: let caller know it failed
    }
  }

  Future<void> addJourney(UmrahJourneyRecord record) async {
    _journeys.add(record);
    notifyListeners();
    await _save();
  }

  Future<void> addOrUpdateJourney(UmrahJourneyRecord record) async {
    final idx = _journeys.indexWhere((j) => j.id == record.id);
    if (idx >= 0) {
      _journeys[idx] = record;
    } else {
      _journeys.add(record);
    }

    await _save(); // ← SAVE FIRST (was after notifyListeners)
    notifyListeners(); // ← Then notify
  }

  Future<void> migrateIfNeeded() async {
    var changed = false;
    for (var j in _journeys) {
      if (j.version == 0) {
        j.version = 1;
        j.completed = j.completed; // keep existing semantics
        changed = true;
      }
    }
    if (changed) await _save();
  }

  Future<void> updateJourney(
    String id, {
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
  }) async {
    final idx = _journeys.indexWhere((j) => j.id == id);
    if (idx < 0) return;
    final j = _journeys[idx];
    if (startTime != null) j.startTime = startTime;
    if (endTime != null) j.endTime = endTime;
    if (notes != null) j.notes = notes;
    notifyListeners();
    await _save();
  }

  /// Update start/end time of a specific checkpoint within a journey.
  /// Returns false if journey not found or journey ended > 24h ago.
  Future<bool> updateCheckpoint(
    String journeyId,
    int checkpointNum, {
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final idx = _journeys.indexWhere((j) => j.id == journeyId);
    if (idx < 0) return false;
    final journey = _journeys[idx];
    if (DateTime.now().difference(journey.endTime) > const Duration(hours: 24)) {
      return false;
    }
    final cpIdx =
        journey.checkpoints.indexWhere((c) => c.checkpointNum == checkpointNum);
    if (cpIdx < 0) return false;
    if (startTime != null) journey.checkpoints[cpIdx].startTime = startTime;
    if (endTime != null) journey.checkpoints[cpIdx].endTime = endTime;
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> deleteJourney(String id) async {
    _journeys.removeWhere((j) => j.id == id);
    notifyListeners();
    await _save();
  }

  UmrahJourneyRecord? getById(String id) => _journeys
      .cast<UmrahJourneyRecord?>()
      .firstWhere((j) => j?.id == id, orElse: () => null);
}
