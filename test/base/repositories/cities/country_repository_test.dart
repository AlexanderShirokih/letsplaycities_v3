import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';

import 'fake_country_loader.dart';

void main() {
  group('CountryRepository.getCountryById', () {
    final repository = CountryRepository(
      FakeCountryLoaderFactory(
        () async => const [
          CountryEntity('Россия', 51, false),
          CountryEntity('Неизвестно', 0, false),
        ],
      ),
      'Unknown country',
    );

    test('finds a listed country', () async {
      expect(
        await repository.getCountryById(51),
        const CountryEntity('Россия', 51, false),
      );
    });

    test('gives the unknown country for an unlisted code', () async {
      expect(
        await repository.getCountryById(70),
        const CountryEntity('Unknown country', 0, false),
      );
    });
  });
}
