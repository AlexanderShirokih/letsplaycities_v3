import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/slang_exclusion_messages.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

void main() {
  final messages = SlangExclusionMessages(AppLocale.ru.buildSync());

  test('each exclusion puts its arguments into its own text', () {
    expect(messages.thisIsACountry('Франция'), 'Франция это страна');
    expect(messages.thisIsAState('Техас'), 'Техас это название штата');
    expect(messages.thisIsNotACity('Пруссия'), 'Пруссия не является городом');
    expect(
      messages.renamedCity('Ленинград', 'Санкт-Петербург'),
      'Город Ленинград ранее был переименован в Санкт-Петербург.',
    );
    expect(
      messages.incompleteCity('Нижний Новгород'),
      'Возможно вы имели в виду город Нижний Новгород ?',
    );
    expect(
      messages.notACity('Переделкино', 'посёлок'),
      'Переделкино не является городом. Это посёлок',
    );
  });
}
