import 'package:meta/meta.dart';

import '../country_entity.dart';
import '../exclusions.dart';

import 'package:lets_play_cities/l18n/localizations_keys.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Exclusion kind
enum ExclusionType {
  CITY_WAS_RENAMED,
  ALTERNATIVE_NAME,
  INCOMPLETE_NAME,
  NOT_A_CITY,
  REGION_NAME
}

/// Structure containing exclusion type and its description|alternative
/// @param type the type of the exclusion
/// @param thing description of exclusion or its alternative writing
class Exclusion {
  final ExclusionType type;
  final String thing;

  const Exclusion(this.type, this.thing)
      : assert(type != null),
        assert(thing != null);
}

/// Manages exclusions for cities.
/// Exclusion types:
///  - City was renamed,
///  - Incomplete name (for ex. city name of two words, but one given
///  - Alternative name (city has two equal names, but only one name can be used in one game)
///  - Not a city (the city not have city status (ex. village)
///  - Region name ( historical regions, states, etc.)
///  - Country name (it's not a city, but country name)
class ExclusionsServiceImpl extends ExclusionsService {
  /// Map of the city name and its exclusion type
  final Map<String, Exclusion> exclusionsList;

  /// Map of string representations of the [ErrorCode]
  final Map<ErrorCode, String> errMessages;

  /// List of country names
  final List<CountryEntity> countries;

  /// List of USA state names
  final List<String> states;

  ExclusionsServiceImpl({
    @required this.exclusionsList,
    @required this.errMessages,
    @required this.countries,
    @required this.states,
  })  : assert(exclusionsList != null),
        assert(errMessages != null),
        assert(countries != null),
        assert(states != null);

  @override
  String checkForExclusion(String city) {
    if (countries
        .any((c) => !c.hasSiblingCity && c.name.toLowerCase() == city)) {
      return errMessages[ErrorCode.THIS_IS_A_COUNTRY]
          .format([city.toTitleCase()]);
    }

    if (states.contains(city)) {
      return errMessages[ErrorCode.THIS_IS_A_STATE]
          .format([city.toTitleCase()]);
    }

    return _checkCity(city);
  }

  String _checkCity(String city) {
    final ex = exclusionsList[city];
    if (ex == null) return '';

    switch (ex.type) {
      case ExclusionType.CITY_WAS_RENAMED: // City was renamed
        return errMessages[ErrorCode.RENAMED_CITY]
            .format([city.toTitleCase(), ex.thing.toTitleCase()]);
      case ExclusionType.INCOMPLETE_NAME: // Incomplete name
        return errMessages[ErrorCode.INCOMPLETE_CITY]
            .format([ex.thing.toTitleCase()]);
      case ExclusionType.NOT_A_CITY: // Geographic object which are not a city
        return errMessages[ErrorCode.NOT_A_CITY]
            .format([city.toTitleCase(), ex.thing]);
      case ExclusionType.REGION_NAME: // Historical site
        return errMessages[ErrorCode.THIS_IS_NOT_A_CITY]
            .format([city.toTitleCase()]);
      default:
        return '';
    }
  }

  @override
  String getAlternativeName(String city) {
    final ex = exclusionsList[city];
    if (ex == null || ex.type != ExclusionType.ALTERNATIVE_NAME) return null;
    return ex.thing;
  }

  @override
  bool hasNoExclusions(String input) {
    final word = input.trim().toLowerCase();
    final noCountryEx =
        countries.every((c) => c.hasSiblingCity || !(c.name == word));
    final noStatesEx = !states.contains(word);
    final notInExclusionsList = !exclusionsList.containsKey(word);

    return noCountryEx && noStatesEx && notInExclusionsList;
  }
}
