import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'journey_record.dart';

class JourneyHistoryProvider extends ChangeNotifier {
  List<UmrahJourneyRecord> _journeys = [];

  List<UmrahJourneyRecord> get journeys =>
      List.unmodifiable(_journeys)..sort((a, b) => b.startTime.compareTo(a.startTime));

  int get totalUmrahCount => _journeys.length;

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
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _journeys = list
          .map((e) => UmrahJourneyRecord.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _save() async {
    final file = await _file();
    await file.writeAsString(jsonEncode(_journeys.map((j) => j.toJson()).toList()));
  }

  Future<void> addJourney(UmrahJourneyRecord record) async {
    _journeys.add(record);
    notifyListeners();
    await _save();
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
