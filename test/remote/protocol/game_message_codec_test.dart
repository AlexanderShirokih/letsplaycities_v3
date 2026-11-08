import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/protocol/game_message_codec.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';

const _codec = GameMessageCodec();

String _fixture(String name) =>
    File('test/remote/protocol/$name.json').readAsStringSync();

void main() {
  group('codec round-trips every testdata json', () {
    final files = Directory('test/remote/protocol')
        .listSync()
        .whereType<File>()
        .map((file) => file.uri.pathSegments.last)
        .where((name) => name.endsWith('.json'))
        .map((name) => name.substring(0, name.length - '.json'.length))
        .toList();

    test('every fixture is covered', () {
      expect(files, hasLength(16));
    });

    for (final name in files) {
      test(name, () {
        final text = _fixture(name);
        final isClient = name.startsWith('client-');

        final encoded = isClient
            ? _codec.encodeClient(_codec.decodeClient(text))
            : _codec.encodeServer(_codec.decodeServer(text));

        expect(jsonDecode(encoded), jsonDecode(text));
      });
    }
  });

  test('decodes the match fixture into typed fields', () {
    final message = _codec.decodeServer(_fixture('server-match'));

    expect(message, isA<Match>());
    final match = message as Match;
    expect(match.gameId, 58231);
    expect(match.opponent.name, 'Дмитрий');
    expect(match.opponent.avatarHash, isNull);
    expect(match.youStart, isTrue);
    expect(match.moveTimeSec, 92);
  });

  test('unknown type throws FormatException', () {
    expect(() => _codec.decodeServer('{"type":"nope"}'), throwsFormatException);
    expect(() => _codec.decodeClient('{"type":"nope"}'), throwsFormatException);
  });

  test('a message of a wrong shape throws FormatException', () {
    expect(() => _codec.decodeServer('[]'), throwsFormatException);
    expect(() => _codec.decodeServer('not json'), throwsFormatException);
    expect(
      () => _codec.decodeServer('{"type":"word","by":"x"}'),
      throwsFormatException,
    );
    expect(
      () => _codec.decodeServer(
        '{"type":"inviteStatus","userId":1,"status":"nope"}',
      ),
      throwsFormatException,
    );
  });
}
