import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/scoring.dart';

void main() {
  group('TimeScoringField.asString', () {
    String format(int seconds) => TimeScoringField('t', seconds).asString();

    test('carries whole minutes and hours', () {
      expect(format(0), '00:00:00');
      expect(format(59), '00:00:59');
      expect(format(60), '00:01:00');
      expect(format(61), '00:01:01');
      expect(format(3599), '00:59:59');
      expect(format(3600), '01:00:00');
      expect(format(3660), '01:01:00');
      expect(format(7260), '02:01:00');
    });
  });

  group('ScoringField.fromJson', () {
    test('reads a time field without a value as zero', () {
      final field = ScoringField.fromJson({'type': 'time', 'name': 't'});

      expect(field, TimeScoringField('t', 0));
    });

    test('reads a time field with a value', () {
      final field = ScoringField.fromJson({
        'type': 'time',
        'name': 't',
        'value': 75,
      });

      expect(field, TimeScoringField('t', 75));
    });
  });
}
