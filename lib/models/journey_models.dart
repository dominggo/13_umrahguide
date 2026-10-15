/// Kind of recorded session. Umrah and Tawaf Wida' are independent: several
/// Umrah journeys may precede a single Tawaf Wida'.
enum JourneyKind {
  umrah(firstCp: 1, lastCp: 17),
  wida(firstCp: 18, lastCp: 24);

  /// Checkpoint numbers owned by this kind (inclusive range).
  final int firstCp;
  final int lastCp;

  const JourneyKind({required this.firstCp, required this.lastCp});

  bool ownsCheckpoint(int num) => num >= firstCp && num <= lastCp;

  static JourneyKind fromName(String? name) =>
      name == 'wida' ? JourneyKind.wida : JourneyKind.umrah;
}

/// A GPS coordinate recorded during a journey
class JourneyPoint {
  final double lat;
  final double lng;
  final DateTime timestamp;

  const JourneyPoint({
    required this.lat,
    required this.lng,
    required this.timestamp,
  });

  factory JourneyPoint.fromJson(Map<String, dynamic> json) => JourneyPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        timestamp: DateTime.parse(json['ts'] as String),
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'ts': timestamp.toIso8601String(),
      };
}

/// Records a single checkpoint (named milestone) during an Umrah journey.
/// A checkpoint starts when the user opens the doa marked checkPointStart,
/// and ends when they confirm the doa marked checkPointEnd.
class CheckpointRecord {
  /// Checkpoint number (1–17 Umrah, 18–24 Tawaf Wida'), matching checkPointStart/checkPointEnd in DoaItem.
  final int checkpointNum;
  final String name;
  DateTime startTime;
  DateTime? endTime;
  final double? lat;
  final double? lng;

  CheckpointRecord({
    required this.checkpointNum,
    required this.name,
    required this.startTime,
    this.endTime,
    this.lat,
    this.lng,
  });

  bool get isCompleted => endTime != null;

  factory CheckpointRecord.fromJson(Map<String, dynamic> json) {
    final latRaw = json['lat'];
    final lngRaw = json['lng'];
    return CheckpointRecord(
      checkpointNum: json['num'] as int,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      lat: latRaw == null ? null : (latRaw as num).toDouble(),
      lng: lngRaw == null ? null : (lngRaw as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'num': checkpointNum,
        'name': name,
        'startTime': startTime.toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };
}
