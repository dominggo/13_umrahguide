import 'package:latlong2/latlong.dart';
import '../models/journey_models.dart';

const _distance = Distance(roundResult: false);

/// Great-circle distance in metres.
double metersBetween(double lat1, double lng1, double lat2, double lng2) =>
    _distance.distance(LatLng(lat1, lng1), LatLng(lat2, lng2));

/// Length of a recorded track in km. Segments that end at a point marked
/// [JourneyPoint.gapBefore] are skipped: the GPS was lost in between, so the
/// straight line is not a walked distance.
double trackDistanceKm(List<JourneyPoint> track) {
  double total = 0;
  for (int i = 1; i < track.length; i++) {
    if (track[i].gapBefore) continue;
    total += metersBetween(
        track[i - 1].lat, track[i - 1].lng, track[i].lat, track[i].lng);
  }
  return total / 1000;
}

/// Splits a track at GPS gaps. [walked] are the recorded stretches; [gaps]
/// are two-point lines bridging each gap (drawn dashed on the map).
({List<List<LatLng>> walked, List<List<LatLng>> gaps}) trackSegments(
    List<JourneyPoint> track) {
  final walked = <List<LatLng>>[];
  final gaps = <List<LatLng>>[];
  var current = <LatLng>[];
  for (int i = 0; i < track.length; i++) {
    final p = LatLng(track[i].lat, track[i].lng);
    if (i > 0 && track[i].gapBefore) {
      if (current.length > 1) walked.add(current);
      gaps.add([LatLng(track[i - 1].lat, track[i - 1].lng), p]);
      current = <LatLng>[];
    }
    current.add(p);
  }
  if (current.length > 1) walked.add(current);
  return (walked: walked, gaps: gaps);
}
