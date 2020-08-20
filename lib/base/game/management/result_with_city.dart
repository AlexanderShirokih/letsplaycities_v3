import 'package:lets_play_cities/base/data.dart';
import 'user_identity.dart';

/// Wrapper class for [WordResult]
class ResultWithCity {
  final WordResult wordResult;
  final String city;
  final UserIdentity identity;

  ResultWithCity({this.wordResult, this.city, this.identity});

  /// Returns `true` is the word was successful applied by server.
  bool isSuccessful() =>
      wordResult == WordResult.ACCEPTED || wordResult == WordResult.RECEIVED;
}
