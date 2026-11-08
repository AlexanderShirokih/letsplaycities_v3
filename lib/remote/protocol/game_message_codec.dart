import 'dart:convert';

import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart';

/// Converts the messages of `WS /v1/game` to and from JSON text. Both sides
/// are here: the client uses the server decoder and the client encoder, the
/// LAN host the other two. Every decoder throws [FormatException] for text
/// that is not a message of its side.
class GameMessageCodec {
  const GameMessageCodec();

  String encodeClient(ClientGameMessage message) =>
      jsonEncode(_clientToJson(message));

  ClientGameMessage decodeClient(String text) => _decode(text, _clientFromJson);

  String encodeServer(ServerGameMessage message) =>
      jsonEncode(_serverToJson(message));

  ServerGameMessage decodeServer(String text) => _decode(text, _serverFromJson);

  T _decode<T>(String text, T Function(String, Map<String, dynamic>) read) {
    final Object? json = jsonDecode(text);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('A message must be a JSON object');
    }

    final type = json['type'];
    if (type is! String) {
      throw const FormatException('A message has no "type"');
    }

    try {
      return read(type, json);
    } on TypeError catch (e) {
      throw FormatException('Malformed "$type" message: $e');
    }
  }

  Map<String, Object?> _clientToJson(ClientGameMessage message) =>
      switch (message) {
        Hello() => {
          'type': 'hello',
          'protocol': message.protocol,
          'client': message.client,
          'name': message.name,
        },
        Find() => {'type': 'find'},
        Invite() => {'type': 'invite', 'userId': message.userId},
        InviteReply() => {
          'type': 'inviteReply',
          'userId': message.userId,
          'accept': message.accept,
        },
        Cancel() => {'type': 'cancel'},
        WordMsg() => {'type': 'word', 'text': message.text},
        ChatMsg() => {'type': 'chat', 'text': message.text},
        Leave() => {'type': 'leave'},
      };

  ClientGameMessage _clientFromJson(String type, Map<String, dynamic> json) =>
      switch (type) {
        'hello' => Hello(
          protocol: json['protocol'] as int,
          client: json['client'] as String,
          name: json['name'] as String? ?? '',
        ),
        'find' => const Find(),
        'invite' => Invite(json['userId'] as int),
        'inviteReply' => InviteReply(
          json['userId'] as int,
          accept: json['accept'] as bool,
        ),
        'cancel' => const Cancel(),
        'word' => WordMsg(json['text'] as String),
        'chat' => ChatMsg(json['text'] as String),
        'leave' => const Leave(),
        _ => throw FormatException('Unknown client message "$type"'),
      };

  Map<String, Object?> _serverToJson(ServerGameMessage message) =>
      switch (message) {
        Welcome() => {'type': 'welcome', 'user': message.user.toJson()},
        Queued() => {'type': 'queued'},
        InviteStatus() => {
          'type': 'inviteStatus',
          'userId': message.userId,
          'status': message.status.name,
        },
        Match() => {
          'type': 'match',
          'gameId': message.gameId,
          'opponent': {
            'id': message.opponent.id,
            'name': message.opponent.name,
            'avatarHash': message.opponent.avatarHash,
            'friendship': message.opponent.friendship.name,
          },
          'youStart': message.youStart,
          'moveTimeSec': message.moveTimeSec,
        },
        WordResultMsg() => {
          'type': 'word',
          'by': message.by,
          'text': message.text,
          'status': message.status.name,
        },
        ChatIn() => {'type': 'chat', 'by': message.by, 'text': message.text},
        GameOver() => {
          'type': 'gameOver',
          'reason': message.reason.name,
          'loser': message.loser,
          'words': message.words,
          'durationSec': message.durationSec,
        },
        ProtocolError() => {'type': 'error', 'code': message.code},
      };

  ServerGameMessage _serverFromJson(String type, Map<String, dynamic> json) =>
      switch (type) {
        'welcome' => Welcome(
          LpsUser.fromJson(json['user'] as Map<String, dynamic>),
        ),
        'queued' => const Queued(),
        'inviteStatus' => InviteStatus(
          json['userId'] as int,
          InviteStatusKind.fromWire(json['status'] as String),
        ),
        'match' => _matchFromJson(json),
        'word' => WordResultMsg(
          json['by'] as int,
          json['text'] as String,
          WordStatus.fromWire(json['status'] as String),
        ),
        'chat' => ChatIn(json['by'] as int, json['text'] as String),
        'gameOver' => GameOver(
          reason: GameOverReason.fromWire(json['reason'] as String),
          loser: json['loser'] as int,
          words: json['words'] as int,
          durationSec: json['durationSec'] as int,
        ),
        'error' => ProtocolError(json['code'] as String),
        _ => throw FormatException('Unknown server message "$type"'),
      };

  Match _matchFromJson(Map<String, dynamic> json) {
    final opponent = json['opponent'] as Map<String, dynamic>;
    final hash = opponent['avatarHash'] as String?;

    return Match(
      gameId: json['gameId'] as int,
      opponent: MatchOpponent(
        id: opponent['id'] as int,
        name: opponent['name'] as String,
        avatarHash: hash == null || hash.isEmpty ? null : hash,
        friendship: Friendship.fromWire(opponent['friendship'] as String),
      ),
      youStart: json['youStart'] as bool,
      moveTimeSec: json['moveTimeSec'] as int,
    );
  }
}
