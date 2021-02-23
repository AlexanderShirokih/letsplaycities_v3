import 'package:flutter/services.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';
import 'package:lets_play_cities/base/dictionary/impl/countrycode_overrides_impl.dart';

/// Helper class used to create [CountryCodeOverrides] service
class CountryCodeOverridesBuilder {
  static const _countryCodeOverridesFile = 'assets/data/overrides.json';

  final String _currentLocale;

  /// Creates new builder instance with [_currentLocale]
  const CountryCodeOverridesBuilder(this._currentLocale);

  Future<CountryCodeOverrides> build() async {
    final data =
        await rootBundle.loadString(_countryCodeOverridesFile, cache: false);
    return CountryCodeOverridesImpl.fromString(data, _currentLocale);
  }
}
