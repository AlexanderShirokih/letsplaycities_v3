import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/users.dart';

/// A local keyboard player: untrusted, so its words go through every check.
Player newPlayer([String name = 'player']) => Player(
  LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
);

/// A non-[Player] user, like the Android or a network opponent.
class FakeOpponent extends User {
  FakeOpponent({super.isTrusted = true, String name = 'opponent'})
    : super(
        accountInfo: LocalAccountInfo(
          name: name,
          picture: const PlaceholderPictureSource(),
        ),
        comboSystem: ComboSystem(canUseQuickTime: false),
      );

  @override
  Future<String> onCreateWord(String firstChar) =>
      throw UnimplementedError('not used by the handler tests');
}
