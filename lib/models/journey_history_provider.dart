import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'journey_models.dart';
import 'journey_record.dart';

class JourneyHistoryProvider extends ChangeNotifier {
  List<UmrahJourneyRecord> _journeys = [];
  String? _errorMsg;
  late final Future<void> _ready;

  // Derived data, rebuilt by _reindex() whenever _journeys changes.
  List<UmrahJourneyRecord> _sorted = const [];
  Map<String, int> _ordinals = const {};

  /// Journeys, newest first.
  List<UmrahJourneyRecord> get journeys => _sorted;

  int get totalUmrahCount =>
      _journeys.where((j) => j.kind == JourneyKind.umrah).length;
  int get totalWidaCount =>
      _journeys.where((j) => j.kind == JourneyKind.wida).length;

  /// 1-based chronological number of journey [id] among records of its kind
  /// (e.g. "Umrah ke-3"); 0 if not found.
  int ordinalOf(String id) => _ordinals[id] ?? 0;

  String? get errorMsg => _errorMsg;

  JourneyHistoryProvider() {
    _ready = _load();
  }

  void _reindex() {
    _sorted = List.unmodifiable(List.of(_journeys)
      ..sort((a, b) => b.startTime.compareTo(a.startTime)));
    final counts = <JourneyKind, int>{};
    final ordinals = <String, int>{};
    for (final j in _sorted.reversed) {
      final n = (counts[j.kind] ?? 0) + 1;
      counts[j.kind] = n;
      ordinals[j.id] = n;
    }
    _ordinals = ordinals;
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/umrah_history.json');
  }

  Future<void> _load() async {
    File? file;
    try {
      file = await _file();
      if (!await file.exists()) return;
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      _journeys = list
          .map((e) => UmrahJourneyRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      _errorMsg = null;
    } catch (e) {
      // Keep the unreadable file aside so the next save can't overwrite it.
      var kept = '';
      try {
        if (file != null && await file.exists()) {
          final ts = DateTime.now().millisecondsSinceEpoch;
          final backup = await file.rename(
              file.path.replaceFirst('.json', '.corrupt-$ts.json'));
          kept = '\nSalinan disimpan: ${backup.path.split('/').last}';
        }
      } catch (_) {}
      _journeys = [];
      _errorMsg = 'Rekod sejarah tidak dapat dibaca: $e$kept';
    } finally {
      _reindex();
      notifyListeners();
    }
  }

  /// Atomic write: a crash mid-write leaves the previous file intact.
  Future<void> _save() async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
        jsonEncode(_journeys.map((j) => j.toJson()).toList()),
        flush: true);
    await tmp.rename(file.path);
  }

  /// Saves first, then notifies; throws if the save fails.
  Future<void> addOrUpdateJourney(UmrahJourneyRecord record) async {
    await _ready;
    final idx = _journeys.indexWhere((j) => j.id == record.id);
    if (idx >= 0) {
      _journeys[idx] = record;
    } else {
      _journeys.add(record);
    }
    _errorMsg = null;
    await _save();
    _changed();
  }

  void _changed() {
    _reindex();
    notifyListeners();
  }

  Future<void> updateJourney(
    String id, {
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
  }) async {
    await _ready;
    final idx = _journeys.indexWhere((j) => j.id == id);
    if (idx < 0) return;
    final j = _journeys[idx];
    if (startTime != null) j.startTime = startTime;
    if (endTime != null) j.endTime = endTime;
    if (notes != null) j.notes = notes;
    _changed();
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
    await _ready;
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
    _changed();
    await _save();
    return true;
  }

  Future<void> deleteJourney(String id) async {
    await _ready;
    _journeys.removeWhere((j) => j.id == id);
    _changed();
    await _save();
  }

  UmrahJourneyRecord? getById(String id) {
    for (final j in _journeys) {
      if (j.id == id) return j;
    }
    return null;
  }
}
