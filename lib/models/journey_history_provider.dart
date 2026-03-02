import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'journey_record.dart';

class JourneyHistoryProvider extends ChangeNotifier {
  List<UmrahJourneyRecord> _journeys = [];
  String? _errorMsg;
  bool _writing = false;

  List<UmrahJourneyRecord> get journeys =>
      List.unmodifiable(_journeys)..sort((a, b) => b.startTime.compareTo(a.startTime));

  int get totalUmrahCount => _journeys.length;
  String? get errorMsg => _errorMsg;

  JourneyHistoryProvider() {
    _load();
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/umrah_history.json');
  }

  Future<File> _tmpFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/umrah_history.json.tmp');
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
    if (_writing) return;
    _writing = true;
    try {
      final tmp = await _tmpFile();
      final file = await _file();
      final content = jsonEncode(_journeys.map((j) => j.toJson()).toList());
      await tmp.writeAsString(content);
      // rename will replace existing file atomically on most platforms
      if (await tmp.exists()) {
        await tmp.rename(file.path);
      }
    } catch (e) {
      _errorMsg = 'Error saving journeys: $e';
      // don't throw; keep in-memory state
    } finally {
      _writing = false;
    }
  }

  Future<void> addJourney(UmrahJourneyRecord record) async {
    _journeys.add(record);
    notifyListeners();
    await _save();
  }

  // NEW: add or update by id
  Future<void> addOrUpdateJourney(UmrahJourneyRecord record) async {
    final idx = _journeys.indexWhere((j) => j.id == record.id);
    if (idx >= 0) {
      _journeys[idx] = record;
    } else {
      _journeys.add(record);
    }
    notifyListeners();
    await _save();
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

  Future<void> deleteJourney(String id) async {
    _journeys.removeWhere((j) => j.id == id);
    notifyListeners();
    await _save();
  }

  UmrahJourneyRecord? getById(String id) =>
      _journeys.cast<UmrahJourneyRecord?>().firstWhere((j) => j?.id == id, orElse: () => null);
}
