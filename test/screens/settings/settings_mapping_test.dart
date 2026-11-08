import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_update_period.dart';
import 'package:lets_play_cities/screens/settings/settings_mapping.dart';

void main() {
  test('timerOptionFor returns the listed value or null', () {
    expect(timerOptionFor(30), 30);
    expect(timerOptionFor(60), 60);
    expect(timerOptionFor(0), 0);
    expect(timerOptionFor(300), isNull);
  });

  test('dictionary switch mapping', () {
    expect(dictionaryUpdatesOn(DictionaryUpdatePeriod.threeHours), isTrue);
    expect(dictionaryUpdatesOn(DictionaryUpdatePeriod.never), isFalse);
    expect(dictionaryPeriodFor(true), DictionaryUpdatePeriod.daily);
    expect(dictionaryPeriodFor(false), DictionaryUpdatePeriod.never);
  });
}
