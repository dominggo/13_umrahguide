import 'journey_models.dart';

class UmrahJourneyRecord {
  final String id;
  DateTime startTime;
  DateTime endTime;
  String? notes;
  final List<JourneyEvent> events;
  final List<JourneyPoint> gpsTrack;

  UmrahJourneyRecord({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.events,
    required this.gpsTrack,
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
  static double _sin2(double x) => _sin(x) * _sin(x);
  static double _sin(double x) => x - x * x * x / 6.0 + x * x * x * x * x / 120.0; // approx
  static double _cos(double x) => 1 - x * x / 2.0 + x * x * x * x / 24.0; // approx
  static double _asin(double x) => x + x * x * x / 6.0; // approx for small x
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double g = x;
    for (int i = 0; i < 10; i++) { g = (g + x / g) / 2; }
    return g;
  }

  factory UmrahJourneyRecord.fromJson(Map<String, dynamic> json) =>
      UmrahJourneyRecord(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: DateTime.parse(json['endTime'] as String),
        notes: json['notes'] as String?,
        events: (json['events'] as List<dynamic>)
            .map((e) => JourneyEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        gpsTrack: (json['gpsTrack'] as List<dynamic>)
            .map((p) => JourneyPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        if (notes != null) 'notes': notes,
        'events': events.map((e) => e.toJson()).toList(),
        'gpsTrack': gpsTrack.map((p) => p.toJson()).toList(),
      };
}
