import 'package:meta/meta.dart';

/// [WordCheckingResult] describes states when [ru.aleshi.letsplaycities.base.player.User] should
/// return after receiving input from keyboard.
@sealed
class WordCheckingResult {}

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

  Accepted(this.word);
}
