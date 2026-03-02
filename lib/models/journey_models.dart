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

/// Event types recorded during a journey
enum JourneyEventType {
  stepStart,
  doaPlayed,
  roundConfirmed,
  journeyStart,
  journeyEnd,
}

class JourneyEvent {
  final JourneyEventType eventType;
  final String? stepId;
  final String? substepId;
  final String? doaTitle;
  final DateTime timestamp;
  final double? lat;
  final double? lng;

  const JourneyEvent({
    required this.eventType,
    this.stepId,
    this.substepId,
    this.doaTitle,
    required this.timestamp,
    this.lat,
    this.lng,
  });

  factory JourneyEvent.fromJson(Map<String, dynamic> json) => JourneyEvent(
        eventType: _typeFromString(json['type'] as String),
        stepId: json['stepId'] as String?,
        substepId: json['substepId'] as String?,
        doaTitle: json['doaTitle'] as String?,
        timestamp: DateTime.parse(json['ts'] as String),
        lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
        lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      );

  Map<String, dynamic> toJson() => {
        'type': _typeToString(eventType),
        if (stepId != null) 'stepId': stepId,
        if (substepId != null) 'substepId': substepId,
        if (doaTitle != null) 'doaTitle': doaTitle,
        'ts': timestamp.toIso8601String(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  static String _typeToString(JourneyEventType t) {
    switch (t) {
      case JourneyEventType.stepStart: return 'step_start';
      case JourneyEventType.doaPlayed: return 'doa_played';
      case JourneyEventType.roundConfirmed: return 'round_confirmed';
      case JourneyEventType.journeyStart: return 'journey_start';
      case JourneyEventType.journeyEnd: return 'journey_end';
    }
  }

  static JourneyEventType _typeFromString(String s) {
    switch (s) {
      case 'step_start': return JourneyEventType.stepStart;
      case 'doa_played': return JourneyEventType.doaPlayed;
      case 'round_confirmed': return JourneyEventType.roundConfirmed;
      case 'journey_end': return JourneyEventType.journeyEnd;
      default: return JourneyEventType.journeyStart;
    }
  }
}

/// Per-step summary for saved journeys
class StepSummary {
  final String stepId;
  DateTime? startedAt;
  DateTime? finishedAt;
  double? lat;
  double? lng;
  bool completed;
  Map<String, dynamic>? meta;

  StepSummary({
    required this.stepId,
    this.startedAt,
    this.finishedAt,
    this.lat,
    this.lng,
    this.completed = false,
    this.meta,
  });

  factory StepSummary.fromJson(Map<String, dynamic> json) => StepSummary(
        stepId: json['stepId'] as String,
        startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'] as String) : null,
        finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt'] as String) : null,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        completed: json['completed'] as bool? ?? false,
        meta: json['meta'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (finishedAt != null) 'finishedAt': finishedAt!.toIso8601String(),
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'completed': completed,
        if (meta != null) 'meta': meta,
      };
}

/// Lightweight snapshot exported by LocationProvider (in-memory or temp)
class UmrahJourneySnapshot {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<JourneyEvent> events;
  final List<JourneyPoint> gpsTrack;
  final bool completed;
  final String? notes;
  final List<StepSummary> stepSummaries;

  UmrahJourneySnapshot({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.events,
    required this.gpsTrack,
    this.completed = false,
    this.notes,
    this.stepSummaries = const [],
  });

  factory UmrahJourneySnapshot.fromJson(Map<String, dynamic> json) => UmrahJourneySnapshot(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
        events: (json['events'] as List<dynamic>)
            .map((e) => JourneyEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        gpsTrack: (json['gpsTrack'] as List<dynamic>)
            .map((p) => JourneyPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        completed: json['completed'] as bool? ?? false,
        notes: json['notes'] as String?,
        stepSummaries: (json['stepSummaries'] as List<dynamic>?)
                ?.map((s) => StepSummary.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        'events': events.map((e) => e.toJson()).toList(),
        'gpsTrack': gpsTrack.map((p) => p.toJson()).toList(),
        'completed': completed,
        if (notes != null) 'notes': notes,
        'stepSummaries': stepSummaries.map((s) => s.toJson()).toList(),
      };
}
