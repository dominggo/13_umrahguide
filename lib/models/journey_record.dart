import '../utils/geo.dart';
import 'journey_models.dart';

class UmrahJourneyRecord {
  final String id;
  DateTime startTime;
  DateTime endTime;
  String? notes;
  final List<JourneyPoint> gpsTrack;

  bool completed;
  int version;
  List<CheckpointRecord> checkpoints;

  /// Umrah journey or standalone Tawaf Wida' session (v3+; older records are Umrah).
  final JourneyKind kind;

  UmrahJourneyRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.gpsTrack,
    this.completed = true,
    this.version = 3,
    this.checkpoints = const [],
    this.kind = JourneyKind.umrah,
  });

  Duration get totalDuration => endTime.difference(startTime);

  double get totalDistanceKm => trackDistanceKm(gpsTrack);

  /// Checkpoint numbers that were started but not ended (in-progress or missed).
  List<int> get missedCheckpointNums {
    final started = {for (final c in checkpoints) c.checkpointNum};
    final completed = {for (final c in checkpoints) if (c.isCompleted) c.checkpointNum};
    return started.difference(completed).toList()..sort();
  }

  factory UmrahJourneyRecord.fromJson(Map<String, dynamic> json) {
    final ver = json['version'] as int? ?? 1;
    return UmrahJourneyRecord(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      notes: json['notes'] as String?,
      gpsTrack: (json['gpsTrack'] as List<dynamic>?)
              ?.map((p) => JourneyPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      completed: json['completed'] as bool? ?? true,
      version: ver,
      // v1 records had events/stepSummaries — migrate to empty checkpoints
      checkpoints: ver >= 2
          ? (json['checkpoints'] as List<dynamic>?)
                  ?.map((c) => CheckpointRecord.fromJson(c as Map<String, dynamic>))
                  .toList() ??
              []
          : [],
      kind: JourneyKind.fromName(json['kind'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        if (notes != null) 'notes': notes,
        'gpsTrack': gpsTrack.map((p) => p.toJson()).toList(),
        'completed': completed,
        'version': version,
        'checkpoints': checkpoints.map((c) => c.toJson()).toList(),
        'kind': kind.name,
      };
}
