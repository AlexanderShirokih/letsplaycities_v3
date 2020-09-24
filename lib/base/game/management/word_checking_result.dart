import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:meta/meta.dart';

/// [WordCheckingResult] describes states when [User] should
/// return after receiving input from keyboard.
@sealed
@immutable
class WordCheckingResult extends GameEvent {
  bool isDescriptiveError() => true;

  bool isSuccessful() => false;
}

/// Used when input [word] has already used.
class AlreadyUsed extends WordCheckingResult {
  final String word;

  AlreadyUsed(this.word);
}

/// Used when input word starts with different letter then [validLetter].
class WrongLetter extends WordCheckingResult {
  final String validLetter;

  WrongLetter(this.validLetter);
}

/// Used when input city is an exclusion and can't be applied.
class Exclusion extends WordCheckingResult {
  final String description;

  Exclusion(this.description);
}

/// Used after state [NotFound] and contains available corrections for current input
class Corrections extends WordCheckingResult {
  final Set<String> corrections;

  Corrections(this.corrections);

  @override
  bool isDescriptiveError() => false;
}

/// Used when no corrections available.
class NotFound extends WordCheckingResult {
  final String word;

  NotFound(this.word);
}

/// Used when input [word] can applied without any corrections.
class Accepted extends WordCheckingResult {
  /// Event producer
  final User owner;

  final String word;

  final CityStatus status;

  final int countryCode;

  @override
  bool isDescriptiveError() => false;

  /// Returns `true` if it approved and accepted word result
  @override
  bool isSuccessful() => status == CityStatus.OK;

  Accepted(this.word, this.owner, {this.status, this.countryCode});

  /// Creates deep copy of object and allows to set some fields
  Accepted clone({CityStatus status, int countryCode}) => Accepted(word, owner,
      status: status ?? this.status,
      countryCode: countryCode ?? this.countryCode);
}

/// Used when error happens during word processing
class Error extends WordCheckingResult {
  final Exception exception;

  Error(this.exception);
}
