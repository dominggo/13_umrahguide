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
