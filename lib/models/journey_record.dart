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

  UmrahJourneyRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.gpsTrack,
    this.completed = true,
    this.version = 2,
    this.checkpoints = const [],
  });

  Duration get totalDuration => endTime.difference(startTime);

  double get totalDistanceKm {
    if (gpsTrack.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < gpsTrack.length; i++) {
      total += _distanceKm(
        gpsTrack[i - 1].lat, gpsTrack[i - 1].lng,
        gpsTrack[i].lat, gpsTrack[i].lng,
      );
    }
    return total;
  }

  /// Checkpoint numbers that were started but not ended (in-progress or missed).
  List<int> get missedCheckpointNums {
    final started = {for (final c in checkpoints) c.checkpointNum};
    final completed = {for (final c in checkpoints) if (c.isCompleted) c.checkpointNum};
    return started.difference(completed).toList()..sort();
  }

  static double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = _sin2(dLat / 2) +
        _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLng / 2);
    final c = 2 * _asin(_sqrt(a));
    return r * c;
  }

  static double _rad(double deg) => deg * 3.141592653589793 / 180;
  static double _sin2(double x) { final s = _sin(x); return s * s; }
  static double _sin(double x) => x - x * x * x / 6.0 + x * x * x * x * x / 120.0;
  static double _cos(double x) => 1 - x * x / 2.0 + x * x * x * x / 24.0;
  static double _asin(double x) => x + x * x * x / 6.0;
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x;
    for (int i = 0; i < 10; i++) { g = (g + x / g) / 2; }
    return g;
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
      };
}
