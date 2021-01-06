import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/player/player.dart';
import 'package:lets_play_cities/base/game/player/users_list.dart';
import 'package:lets_play_cities/base/platform/app_version.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/incoming_models.dart';
import 'package:lets_play_cities/remote/model/outgoing_models.dart';
import 'package:lets_play_cities/remote/client/socket_api.dart';
import 'package:lets_play_cities/remote/handlers/network_interceptor.dart';
import 'package:lets_play_cities/remote/remote_player.dart';
import 'package:meta/meta.dart';

/// Describes rules and order of sending mess
class RemoteGameClient {
  final RemoteAccount account;
  final SocketApi socketApi;
  final Future<String> firebaseToken;
  final GamePreferences preferences;

  const RemoteGameClient({
    @required this.account,
    @required this.socketApi,
    @required this.firebaseToken,
    @required this.preferences,
  })  : assert(account != null),
        assert(socketApi != null),
        assert(firebaseToken != null),
        assert(preferences != null);

  /// Starts connection to the server
  Future<void> connect() {
    socketApi.connect();

    // Wait for connection established
    return socketApi.messages
        .firstWhere((element) => element is ConnectedMessage);
  }

  /// Does the authorization sequence
  /// Throws [AuthorizationException] if user cannot be authorized on server
  /// Throws any other kinds of [RemoteException] if some error happens
  Future<void> logIn(Credential credential) async {
    final fbToken = await firebaseToken;
    final version = await getAppVersion();

    socketApi.sendMessage(LogInMessage(
      clientBuild: version.buildNumber,
      clientVersion: version.version,
      canReceiveMessages: preferences.onlineChatEnabled,
      firebaseToken: fbToken,
      uid: credential.userId,
      hash: credential.accessToken,
    ));

    // Wait for login result
    final authResult = await socketApi.messages.first;

    if (authResult is LoggedInMessage) {
      /// Authorization was successful
      return;
    } else if (authResult is BannedMessage) {
      throw AuthorizationException(
          authResult.banReason ?? 'Authorization failed!');
    } else {
      throw UnknownMessageException(
          'Unexpected message at login sequence: ${authResult}');
    }
  }

  /// Sends play message to stand on playing queue or connect to specified
  /// [opponent].
  /// Waits for opponent and then returns list of game players.
  /// First player in list make move first
  Future<GameConfig> play(BaseProfileInfo opponent) async {
    socketApi.sendMessage(PlayMessage(
      mode: opponent == null ? PlayMode.RANDOM_PAIR : PlayMode.FRIEND,
      oppUid: opponent?.userId,
    ));

    final join = await socketApi.messages
        .firstWhere((element) => element is JoinMessage) as JoinMessage;

    final owningPlayer = Player(account);
    final opponentPlayer = RemotePlayer(
        AdvancedAccountInfo(
          join.opponent,
          join.canReceiveMessages,
        ),
        this);

    final users = join.youStarter
        ? <User>[owningPlayer, opponentPlayer]
        : <User>[opponentPlayer, owningPlayer];

    return GameConfig(
        gameMode: GameMode.Network,
        usersList: UsersList(users),
        timeLimit: 92,
        additionalEventHandlers: [NetworkInterceptor(this)]);
  }

  /// Closes current connection
  Future<void> disconnect() => socketApi.close();

  /// Sends word for checking and awaits for checking result
  Future<WordResult> sendWord(ClientAccountInfo owner, String word) async {
    socketApi.sendMessage(OutgoingWordMessage(word: word));

    return _getInputWordsFor(owner).first.then((res) => res.result);
  }

  /// Returns a stream of word messages with result [WordResult.RECEIVED] for
  /// [owner]
  Stream<String> getInputWords(ClientAccountInfo owner) =>
      _getInputWordsFor(owner)
          .where((wordMessage) => wordMessage.result == WordResult.RECEIVED)
          .map((wordMessage) => wordMessage.word);

  Stream<WordMessage> _getInputWordsFor(ClientAccountInfo owner) =>
      socketApi.messages
          .where((element) => element is WordMessage)
          .cast<WordMessage>()
          .where((result) => _extractId(owner) == result.ownerId);

  /// Sends chat message
  Future sendChatMessage(String message) async {
    socketApi.sendMessage(OutgoingChatMessage(msg: message));
    return;
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
