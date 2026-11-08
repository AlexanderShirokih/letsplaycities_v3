import 'package:lets_play_cities/base/dictionary/error_code.dart';

/// Explains to the player why a word is not accepted as a city, one method
/// per [ErrorCode]. The caller supplies the texts, so the dictionary code
/// does not depend on how the app stores its strings.
abstract interface class ExclusionMessages {
  /// [ErrorCode.thisIsACountry]: [city] is the name of a country.
  String thisIsACountry(String city);

  /// [ErrorCode.thisIsAState]: [city] is the name of a state.
  String thisIsAState(String city);

  /// [ErrorCode.thisIsNotACity]: [city] names a region, not a city.
  String thisIsNotACity(String city);

  /// [ErrorCode.renamedCity]: [city] was renamed to [newName].
  String renamedCity(String city, String newName);

  /// [ErrorCode.incompleteCity]: the player probably meant [city].
  String incompleteCity(String city);

  /// [ErrorCode.notACity]: [city] is a [kind] of place, not a city.
  String notACity(String city, String kind);
}
