import 'package:lets_play_cities/base/game/word_checking_result.dart';

/// Implemented by classes that should handle user input
abstract class UserInputConsumer {
  /// Call to handle current user input. Emits [WordCheckingResult] childs.
  /// User input considered completed only if [Accepted] event was emitted.
  Stream<WordCheckingResult> onUserInput(String input);
}
