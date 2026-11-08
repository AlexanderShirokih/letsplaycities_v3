import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/impl/country_code_overrides_builder.dart';
import 'package:lets_play_cities/base/dictionary/impl/countrycode_overrides_impl.dart';

const _overrides = '''
[
  {
    "locales": ["ua", "uk"],
    "target": 196,
    "cities": ["щёлкино", "Ялта"]
  }
]
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CountryCodeOverridesImpl', () {
    test('matches normalized city names', () {
      final overrides = CountryCodeOverridesImpl.fromString(
        _overrides,
        'uk_UA',
      );

      expect(overrides.findOverride('щелкино'), 196);
      expect(overrides.findOverride('ялта'), 196);
    });

    test('skips groups for other locales', () {
      final overrides = CountryCodeOverridesImpl.fromString(
        _overrides,
        'ru_RU',
      );

      expect(overrides.findOverride('щелкино'), isNull);
    });

    test('bundled overrides match the normalized spelling', () async {
      final overrides = await CountryCodeOverridesBuilder('uk_UA').build();

      expect(overrides.findOverride('щелкино'), 196);
      expect(overrides.findOverride('ялта'), 196);
    });
  });
}
