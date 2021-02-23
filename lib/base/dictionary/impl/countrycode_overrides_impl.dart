import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/dictionary/countrycode_overrides.dart';

class _OverrideEntity extends Equatable {
  final List<String> locales;
  final String name;
  final int target;

  const _OverrideEntity({
    required this.locales,
    required this.name,
    required this.target,
  });

  @override
  List<Object?> get props => [locales, name, target];
}

/// Country code implementation that uses a map of country code overrides
class CountryCodeOverridesImpl implements CountryCodeOverrides {
  final Map<String, int> _overrides;

  const CountryCodeOverridesImpl._(this._overrides);

  factory CountryCodeOverridesImpl.fromString(
          String data, String currentLocale) =>
      CountryCodeOverridesImpl._(
        {
          for (var override in (jsonDecode(data) as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .expand((overrideGroup) {
            final int target = overrideGroup['target'];
            final locales = (overrideGroup['locales'] as List<dynamic>)
                .cast<String>()
                .toList(growable: false);
            return (overrideGroup['cities'] as List<dynamic>)
                .cast<String>()
                .map(
                  (city) => _OverrideEntity(
                    locales: locales,
                    name: city,
                    target: target,
                  ),
                );
          }).where((element) {
            final localeRegex = RegExp('(${element.locales.join('|')})');
            return currentLocale.contains(localeRegex);
          }))
            override.name: override.target,
        },
      );

  @override
  int? findOverride(String word) => _overrides[word];
}
