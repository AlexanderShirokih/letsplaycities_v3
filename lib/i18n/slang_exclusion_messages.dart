import 'package:lets_play_cities/base/dictionary/exclusion_messages.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

/// [ExclusionMessages] taken from the `exclusionList` strings of [_t].
class SlangExclusionMessages implements ExclusionMessages {
  final Translations _t;

  const SlangExclusionMessages(this._t);

  @override
  String thisIsACountry(String city) =>
      _t.exclusionList.thisIsACountry(city: city);

  @override
  String thisIsAState(String city) => _t.exclusionList.thisIsAState(city: city);

  @override
  String thisIsNotACity(String city) =>
      _t.exclusionList.thisIsNotACity(city: city);

  @override
  String renamedCity(String city, String newName) =>
      _t.exclusionList.renamedCity(city: city, newName: newName);

  @override
  String incompleteCity(String city) =>
      _t.exclusionList.incompleteCity(city: city);

  @override
  String notACity(String city, String kind) =>
      _t.exclusionList.notACity(city: city, kind: kind);
}
