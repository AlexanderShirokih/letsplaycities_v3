import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/player/default_player_names.dart';
import 'package:lets_play_cities/base/game/player/surrender_exception.dart';
import 'package:lets_play_cities/base/users.dart';

import 'fakes.dart';

const _names = DefaultPlayerNames(
  player: 'Player',
  android: 'Android',
  firstPlayer: 'First',
  secondPlayer: 'Second',
);

void main() {
  test('seats the first user on the left and the second on the right', () {
    final first = createPlayer('first');
    final second = createPlayer('second');

    final users = UsersList([first, second]);

    expect(first.position, Position.left);
    expect(second.position, Position.right);
    expect(users.getUserByPosition(Position.left), same(first));
    expect(users.getUserByPosition(Position.right), same(second));
    expect(() => users.getUserByPosition(Position.unknown), throwsStateError);
  });

  test('the first user moves first and turns alternate', () {
    final first = createPlayer('first');
    final second = createPlayer('second');
    final users = UsersList([first, second]);

    expect(users.first, same(first));
    expect(users.current, same(first));
    expect(users.next, same(second));

    users.switchToNext();
    expect(users.current, same(second));
    expect(users.next, same(first));

    users.switchToNext();
    expect(users.current, same(first));
  });

  test('the current user can be set directly', () {
    final first = createPlayer('first');
    final second = createPlayer('second');
    final users = UsersList([first, second]);

    users.current = second;

    expect(users.current, same(second));
    expect(users.next, same(first));
  });

  test('has no current player while it is the Android\'s turn', () {
    final player = createPlayer();
    final android = Android(FakeDictionary(), 'android');
    final users = UsersList([player, android]);

    expect(users.currentPlayer, same(player));

    users.switchToNext();

    expect(users.current, same(android));
    expect(users.currentPlayer, isNull);
  });

  group('forGameMode', () {
    test('plays the player against Android', () {
      final users = UsersList.forGameMode(
        GameMode.playerVsAndroid,
        FakeDictionary(),
        _names,
      );

      expect(users.all, [isA<Player>(), isA<Android>()]);
      expect(users.all.map((u) => u.name), ['Player', 'Android']);
      expect(users.current, isA<Player>());
    });

    test('plays two players on one device', () {
      final users = UsersList.forGameMode(
        GameMode.playerVsPlayer,
        FakeDictionary(),
        _names,
      );

      expect(users.all, [isA<Player>(), isA<Player>()]);
      expect(users.all.map((u) => u.name), ['First', 'Second']);
    });

    test('does not build the users of network games', () {
      for (final mode in [GameMode.network, GameMode.multiplayer]) {
        expect(
          () => UsersList.forGameMode(mode, FakeDictionary(), _names),
          throwsA(isA<String>()),
          reason: '$mode',
        );
      }
    });
  });

  test('close ends the move of a player who is still thinking', () async {
    final player = createPlayer();
    final users = UsersList([player, createPlayer('second')]);

    final word = expectLater(
      player.onCreateWord('а'),
      throwsA(
        isA<SurrenderException>().having(
          (e) => e.byDisconnection,
          'byDisconnection',
          isTrue,
        ),
      ),
    );
    await users.close();

    await word;
  });
}
