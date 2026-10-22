import 'package:flutter_test/flutter_test.dart';
import 'package:umrah_guide/data/umrah_data.dart';
import 'package:umrah_guide/models/journey_models.dart';

void main() {
  group('JourneyPoint json', () {
    test('old point without gap loads as no gap', () {
      final p = JourneyPoint.fromJson(
          {'lat': 21.4, 'lng': 39.8, 'ts': '2026-01-01T10:00:00.000'});
      expect(p.gapBefore, isFalse);
      expect(p.toJson().containsKey('gap'), isFalse);
    });

    test('gap round-trips', () {
      final p = JourneyPoint(
          lat: 21.4, lng: 39.8, timestamp: DateTime(2026), gapBefore: true);
      final again = JourneyPoint.fromJson(p.toJson());
      expect(again.gapBefore, isTrue);
    });
  });

  group('checkpoint lookup', () {
    test('every checkpoint 1–24 resolves to the doa that starts it', () {
      for (final kind in JourneyKind.values) {
        for (var n = kind.firstCp; n <= kind.lastCp; n++) {
          final loc = checkpointStartLocation(n);
          expect(loc, isNotNull, reason: 'CP$n');
          final flat = [for (final s in loc!.step.subSteps) ...s.duas];
          expect(flat[loc.flatIndex].checkPointStart, n, reason: 'CP$n');
        }
      }
    });

    test('names use checkPointName or the substep title', () {
      for (var n = 1; n <= 24; n++) {
        String? expected;
        for (final step in umrahSteps) {
          for (final sub in step.subSteps) {
            for (final doa in sub.duas) {
              if (expected == null && doa.checkPointStart == n) {
                expected = doa.checkPointName ?? sub.title;
              }
            }
          }
        }
        expect(checkpointName(n), expected, reason: 'CP$n');
      }
    });

    test('unknown checkpoint', () {
      expect(checkpointStartLocation(99), isNull);
      expect(checkpointName(99), 'Checkpoint 99');
    });
  });
}
