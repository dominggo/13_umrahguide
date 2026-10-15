import 'package:flutter_test/flutter_test.dart';
import 'package:umrah_guide/data/umrah_data.dart';
import 'package:umrah_guide/models/journey_models.dart';
import 'package:umrah_guide/models/journey_record.dart';

void main() {
  Map<String, dynamic> baseJson() => {
        'id': 'a',
        'startTime': '2026-01-01T10:00:00.000',
        'endTime': '2026-01-01T12:00:00.000',
        'gpsTrack': <dynamic>[],
        'completed': true,
        'checkpoints': <dynamic>[],
      };

  test('v2 record without kind loads as umrah', () {
    final r = UmrahJourneyRecord.fromJson({...baseJson(), 'version': 2});
    expect(r.kind, JourneyKind.umrah);
    expect(r.version, 2);
  });

  test('wida kind round-trips through json', () {
    final r = UmrahJourneyRecord.fromJson(
        {...baseJson(), 'version': 3, 'kind': 'wida'});
    expect(r.kind, JourneyKind.wida);
    final again = UmrahJourneyRecord.fromJson(r.toJson());
    expect(again.kind, JourneyKind.wida);
    expect(again.version, 3);
  });

  test('checkpoint ranges do not overlap', () {
    expect(JourneyKind.umrah.ownsCheckpoint(17), isTrue);
    expect(JourneyKind.umrah.ownsCheckpoint(18), isFalse);
    expect(JourneyKind.wida.ownsCheckpoint(18), isTrue);
    expect(JourneyKind.wida.ownsCheckpoint(24), isTrue);
    expect(JourneyKind.wida.ownsCheckpoint(17), isFalse);
  });

  test('every checkpoint of each kind has exactly one start and one end', () {
    final starts = <int>[];
    final ends = <int>[];
    for (final step in umrahSteps) {
      for (final sub in step.subSteps) {
        for (final doa in sub.duas) {
          if (doa.checkPointStart != null) starts.add(doa.checkPointStart!);
          if (doa.checkPointEnd != null) ends.add(doa.checkPointEnd!);
        }
      }
    }
    for (final kind in JourneyKind.values) {
      for (var n = kind.firstCp; n <= kind.lastCp; n++) {
        expect(starts.where((x) => x == n).length, 1, reason: 'start CP$n');
        expect(ends.where((x) => x == n).length, 1, reason: 'end CP$n');
      }
    }
  });
}
