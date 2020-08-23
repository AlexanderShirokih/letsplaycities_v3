import 'package:meta/meta.dart';

/// [WordCheckingResult] describes states when [User] should
/// return after receiving input from keyboard.
@sealed
@immutable
class WordCheckingResult {
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
  final List<String> corrections;

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
/// Note that [word] can be formatted to proper format.
class Accepted extends WordCheckingResult {
  final String word;

  @override
  bool isDescriptiveError() => false;

  bool isSuccessful() => true;

  Accepted(this.word);
}
