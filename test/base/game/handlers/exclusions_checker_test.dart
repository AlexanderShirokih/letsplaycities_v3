import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/game/handlers.dart';
import 'package:lets_play_cities/base/game/management.dart';

import 'fake_users.dart';

class _FakeExclusions extends Fake implements ExclusionsService {
  final Map<String, String> descriptions;
  final checked = <String>[];

  _FakeExclusions(this.descriptions);

  @override
  String checkForExclusion(String city) {
    checked.add(city);
    return descriptions[city] ?? '';
  }
}

void main() {
  test('rejects an excluded word with the exclusion description', () async {
    final exclusions = _FakeExclusions({'ссср': 'это страна, а не город'});

    final result = await ExclusionsChecker(exclusions)
        .process(RawWordEvent('ссср', newPlayer()))
        .toList();

    expect(result, [
      isA<Exclusion>().having(
        (e) => e.description,
        'description',
        'это страна, а не город',
      ),
    ]);
  });

  test('passes a word without exclusions on to the next check', () async {
    final exclusions = _FakeExclusions({'ссср': 'это страна, а не город'});
    final word = RawWordEvent('москва', newPlayer());

    final result = await ExclusionsChecker(exclusions).process(word).toList();

    expect(result, [same(word)]);
    expect(exclusions.checked, ['москва']);
  });

  test('does not check events other than words', () async {
    final exclusions = _FakeExclusions({});
    const event = OnFirstCharChanged('а');

    final result = await ExclusionsChecker(exclusions).process(event).toList();

    expect(result, [same(event)]);
    expect(exclusions.checked, isEmpty);
  });
}
