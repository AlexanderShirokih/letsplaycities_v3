import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/users.dart';

/// Dictionary that answers every request with [words], one after another,
/// and then with an empty string, which means "no words left".
class FakeDictionary extends Fake implements DictionaryDecorator {
  @override
  final Difficulty difficulty;

  final List<String> words;

  /// First chars Android asked for, in order.
  final requests = <String>[];

  FakeDictionary({this.difficulty = Difficulty.easy, this.words = const []});

  @override
  Future<String> getRandomWord(String firstChar) async {
    requests.add(firstChar);
    return requests.length <= words.length ? words[requests.length - 1] : '';
  }
}

/// Dictionary that never runs out of words.
class EndlessDictionary extends Fake implements DictionaryDecorator {
  @override
  final Difficulty difficulty;

  EndlessDictionary(this.difficulty);

  @override
  Future<String> getRandomWord(String firstChar) async => '$firstChar-город';
}

/// [Random] whose [nextDouble] always returns [value].
class FixedRandom implements Random {
  final double value;

  FixedRandom(this.value);

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  int nextInt(int max) => throw UnimplementedError();
}

Player createPlayer([String name = 'player']) => Player(
  LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
);
