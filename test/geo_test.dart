import 'package:flutter_test/flutter_test.dart';
import 'package:umrah_guide/models/journey_models.dart';
import 'package:umrah_guide/utils/geo.dart';

void main() {
  final t = DateTime(2026, 1, 1);
  JourneyPoint p(double lat, double lng, {bool gap = false}) =>
      JourneyPoint(lat: lat, lng: lng, timestamp: t, gapBefore: gap);

  test('metersBetween: 0.001° latitude is about 111 m', () {
    final d = metersBetween(21.4220, 39.8262, 21.4230, 39.8262);
    expect(d, closeTo(110.7, 1.0));
  });

  test('trackDistanceKm sums segments', () {
    final track = [p(21.4220, 39.8262), p(21.4230, 39.8262), p(21.4240, 39.8262)];
    expect(trackDistanceKm(track), closeTo(0.2214, 0.002));
  });

  test('trackDistanceKm skips the segment across a GPS gap', () {
    final track = [
      p(21.4220, 39.8262),
      p(21.4230, 39.8262),
      p(21.4300, 39.8262, gap: true), // jump after lost GPS
      p(21.4310, 39.8262),
    ];
    expect(trackDistanceKm(track), closeTo(0.2214, 0.002));
  });

  test('trackSegments splits walked parts and bridges gaps', () {
    final seg = trackSegments([
      p(1, 1),
      p(1.001, 1),
      p(1.01, 1, gap: true),
      p(1.011, 1),
    ]);
    expect(seg.walked.length, 2);
    expect(seg.gaps.length, 1);
    expect(seg.gaps.single.first.latitude, 1.001);
    expect(seg.gaps.single.last.latitude, 1.01);
  });

  test('empty and single-point tracks have no distance', () {
    expect(trackDistanceKm([]), 0);
    expect(trackDistanceKm([p(1, 1)]), 0);
    expect(trackSegments([p(1, 1)]).walked, isEmpty);
  });
}
