import '../country_entity.dart';
import '../exclusion_messages.dart';
import '../exclusions.dart';

import 'package:lets_play_cities/utils/string_utils.dart';

/// Exclusion kind
enum ExclusionType {
  cityWasRenamed,
  alternativeName,
  incompleteName,
  notACity,
  regionName,
}

/// Structure containing exclusion type and its description|alternative
/// @param type the type of the exclusion
/// @param thing description of exclusion or its alternative writing
class Exclusion {
  final ExclusionType type;
  final String thing;

  const Exclusion(this.type, this.thing);
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

  /// Texts that explain an exclusion to the player
  final ExclusionMessages messages;

  /// List of country names
  final List<CountryEntity> countries;

  /// List of USA state names
  final List<String> states;

  ExclusionsServiceImpl({
    required this.exclusionsList,
    required this.messages,
    required this.countries,
    required this.states,
  });

  @override
  String checkForExclusion(String city) {
    if (countries.any(
      (c) => !c.hasSiblingCity && c.name.toLowerCase() == city,
    )) {
      return messages.thisIsACountry(city.toTitleCase());
    }

    if (states.contains(city)) {
      return messages.thisIsAState(city.toTitleCase());
    }

    return _checkCity(city);
  }

  String _checkCity(String city) {
    final ex = exclusionsList[city];
    if (ex == null) return '';

    switch (ex.type) {
      case ExclusionType.cityWasRenamed: // City was renamed
        return messages.renamedCity(city.toTitleCase(), ex.thing.toTitleCase());
      case ExclusionType.incompleteName: // Incomplete name
        return messages.incompleteCity(ex.thing.toTitleCase());
      case ExclusionType.notACity: // Geographic object which are not a city
        return messages.notACity(city.toTitleCase(), ex.thing);
      case ExclusionType.regionName: // Historical site
        return messages.thisIsNotACity(city.toTitleCase());
      default:
        return '';
    }
  }

  @override
  String? getAlternativeName(String city) {
    final ex = exclusionsList[city];
    if (ex == null || ex.type != ExclusionType.alternativeName) return null;
    return ex.thing;
  }

  @override
  bool hasNoExclusions(String input) {
    final word = input.trim().toLowerCase();
    final noCountryEx = countries.every(
      (c) => c.hasSiblingCity || !(c.name == word),
    );
    final noStatesEx = !states.contains(word);
    final notInExclusionsList = !exclusionsList.containsKey(word);

    return noCountryEx && noStatesEx && notInExclusionsList;
  }
}
