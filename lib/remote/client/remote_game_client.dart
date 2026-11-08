import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/game_session.dart';
import 'package:lets_play_cities/base/platform/app_version.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/socket_api.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/handlers/network_interceptor.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/remote_player.dart';

/// Describes rules and order of sending messages
class RemoteGameClient {
  final RemoteAccount account;
  final SocketApi socketApi;
  final Future<String> firebaseToken;
  final GamePreferences preferences;

  /// Whether the server is a LAN host rather than the main server: a local
  /// game is played in [GameMode.multiplayer] instead of [GameMode.network].
  /// Called each time an opponent joins, not once when the client is built.
  final bool Function() isLocal;

  const RemoteGameClient({
    required this.account,
    required this.socketApi,
    required this.firebaseToken,
    required this.preferences,
    required this.isLocal,
  });

  /// Starts connection to the server
  Future<void> connect() {
    socketApi.connect();

    // Wait for connection established
    return socketApi.messages.firstWhere(
      (element) => element is ConnectedMessage,
    );
  }

  /// Does the authorization sequence.
  /// Throws [AuthorizationException] if user cannot be authorized on server.
  /// Throws any other kinds of [RemoteException] if some error happens
  Future<void> logIn(Credential credential) async {
    final fbToken = await firebaseToken;
    final version = VersionInfoService.instance;

    socketApi.sendMessage(
      LogInMessage(
        clientBuild: version.build,
        clientVersion: version.name,
        canReceiveMessages: preferences.onlineChatEnabled,
        firebaseToken: fbToken,
        uid: credential.userId,
        hash: credential.accessToken,
      ),
    );

    // Wait for login result
    final authResult = await socketApi.messages.first;

    if (authResult is LoggedInMessage) {
      /// Authorization was successful
      return;
    } else if (authResult is BannedMessage) {
      throw AuthorizationException(
        authResult.banReason ?? 'Authorization failed!',
      );
    } else {
      throw UnknownMessageException(
        'Unexpected message at login sequence: $authResult',
      );
    }
  }

  /// Sends play message to stand on playing queue.
  /// Waits for opponent and then returns list of game players.
  /// First player in list make move first
  Future<GameConfig> play() async {
    socketApi.sendMessage(PlayMessage(mode: PlayMode.randomPair, oppUid: null));

    final response = await socketApi.messages.firstWhere(
      (element) => element is JoinMessage || element is DisconnectedMessage,
      orElse: () => throw ConnectionException('Connection interrupted'),
    );

    if (response is! JoinMessage) {
      throw ConnectionException('Connection interrupted');
    }

    return _buildGameConfig(response);
  }

  GameConfig _buildGameConfig(JoinMessage join) {
    final owningPlayer = Player(account);
    final opponentPlayer = RemotePlayer(
      AdvancedAccountInfo(join.opponent, join.canReceiveMessages),
      this,
    );

    final users = join.youStarter
        ? <User>[owningPlayer, opponentPlayer]
        : <User>[opponentPlayer, owningPlayer];

    return GameConfig(
      gameMode: isLocal() ? GameMode.multiplayer : GameMode.network,
      usersListOverride: UsersList(users),
      timeLimitOverride: 92,
      externalEventSource: _translateServiceEvents,
      additionalEventHandlers: [NetworkInterceptor(this)],
    );
  }

  /// Sends friend-mode [request] (when request is [FriendGameRequestType.invite])
  /// or positive result to input request (when request is [FriendGameRequestType.join]).
  /// Opponent should be in users friend list.
  /// Returns either [GameConfig] when opponent accepts the game
  /// or [InvitationResponseMessage] if opponent declines the request or
  /// it is unreachable.
  Future<dynamic> invite(FriendGameRequest request) async {
    switch (request.mode) {
      case FriendGameRequestType.invite:
        socketApi.sendMessage(
          PlayMessage(mode: PlayMode.friend, oppUid: request.target.userId),
        );
        break;
      case FriendGameRequestType.join:
        socketApi.sendMessage(
          InvitationResultMessage(
            result: InvitationResult.accept,
            oppId: request.target.userId,
          ),
        );
        break;
    }

    final response = await socketApi.messages.firstWhere(
      (element) =>
          element is InvitationResponseMessage ||
          element is JoinMessage ||
          element is DisconnectedMessage,
      orElse: () => throw ConnectionException('Connection interrupted'),
    );

    if (response is JoinMessage) {
      // Opponent accepts the request. We can start the game
      return _buildGameConfig(response);
    } else if (response is InvitationResponseMessage) {
      // Opponent declines request or another bad response
      return response;
    } else if (response is DisconnectedMessage) {
      throw ConnectionException('Connection interrupted');
    } else {
      throw 'Unexpected situation!';
    }
  }

  /// Closes current connection
  Future<void> disconnect() => socketApi.close();

  /// Sends word for checking and awaits for checking result
  Future<WordResult> sendWord(ClientAccountInfo owner, String word) async {
    socketApi.sendMessage(OutgoingWordMessage(word: word));

    return _getInputWordsFor(owner).first.then((res) => res.result);
  }

  /// Returns a stream of word messages with result [WordResult.received] for
  /// [owner]
  Stream<String> getInputWords(ClientAccountInfo owner) =>
      _getInputWordsFor(owner)
          .where((wordMessage) => wordMessage.result == WordResult.received)
          .map((wordMessage) => wordMessage.word);

  Stream<WordMessage> _getInputWordsFor(ClientAccountInfo owner) => socketApi
      .messages
      .where((element) => element is WordMessage)
      .cast<WordMessage>()
      .where((result) => _extractId(owner) == result.ownerId);

  /// Sends chat message
  Future sendChatMessage(String message) async {
    socketApi.sendMessage(OutgoingChatMessage(msg: message));
    return;
  }

  /// Sends invitation result for previously received request
  Future sendInvitationResult(
    BaseProfileInfo sender,
    InvitationResult result,
  ) async {
    socketApi.sendMessage(
      InvitationResultMessage(result: result, oppId: sender.userId),
    );
    return;
  }

  Stream<GameEvent> _translateServiceEvents(GameSession session) async* {
    EquatableConfig.stringify = true;
    await for (final message in socketApi.messages) {
      if (message is ChatMessage) {
        final user = session.usersList.all.singleWhere(
          (u) => _extractId(u.accountInfo) == message.ownerId,
        );
        yield MessageEvent(message.message, user);
      } else if (message is DisconnectedMessage) {
        yield OnMoveFinished(
          MoveFinishType.disconnected,
          session.usersList.all.firstWhere((u) => u is! Player),
        );
      } else if (message is TimeoutMessage) {
        yield OnMoveFinished(MoveFinishType.timeout, session.usersList.current);
      }
    }
  }

  int _extractId(ClientAccountInfo account) {
    if (account is RemoteAccount) {
      return account.credential.userId;
    } else if (account is AdvancedAccountInfo) {
      return account.profileInfo.userId;
    } else {
      throw RemoteException('Cannot extract ID from received account info');
    }
  }
}
