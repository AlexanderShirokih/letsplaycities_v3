import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/utils/minutes_seconds.dart';

void main() {
  test('toMinutesSeconds() splits seconds into minutes and seconds', () {
    expect(toMinutesSeconds(0), (minutes: 0, seconds: 0));
    expect(toMinutesSeconds(59), (minutes: 0, seconds: 59));
    expect(toMinutesSeconds(60), (minutes: 1, seconds: 0));
    expect(toMinutesSeconds(75), (minutes: 1, seconds: 15));
  });

  test('toMinutesSeconds() does not roll minutes over into hours', () {
    expect(toMinutesSeconds(3600), (minutes: 60, seconds: 0));
  });
}
