import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';

/// Handles LPS protocol interactions with particular client
abstract class LpsServerInteractor {
  /// Authorizes client on the server
  Future<ProfileInfo> authorize();

  /// Waits for 'join' message to be sent
  Future<void> awaitStart();

  /// Closes current connection
  Future<void> close();
}

/// Implementation of [LpsServerInteractor]
class LpsServerInteractorImpl extends LpsServerInteractor {
  final MessagePipe<ClientMessage, ServerMessage> _client;
  final ProfileInfo _owner;
  final GamePreferences _prefs;

  LpsServerInteractorImpl(this._client, this._owner, this._prefs);

  @override
  Future<ProfileInfo> authorize() async {
    final loginRequest = await _client.readMessage() as LogInMessage;
    final version = loginRequest.version;

    if (5 != version) {
      throw RemoteException(
          'Incompatible protocol versions(5 != $version)! Please, upgrade your application');
    }

    await _client.sendMessage(LoggedInMessage(newerBuild: 1));

    return ProfileInfo(
      userId: loginRequest.uid,
      login: 'StartHTTPAndUpgrToSocket',
      pictureUrl: null,
      role: Role.regular,
      lastVisitDate: DateTime.now(),
      banStatus: BanStatus.notBanned,
      friendshipStatus: FriendshipStatus.friends,
      authType: AuthType.Native,
    );
  }

  @override
  Future<void> awaitStart() async {
    final playRequest = await _client.readMessage() as PlayMessage;

    if (playRequest.mode != PlayMode.RANDOM_PAIR) {
      throw RemoteException('Protocol error: invalid play mode!');
    }

    await _client.sendMessage(JoinMessage(
      canReceiveMessages: _prefs.onlineChatEnabled,
      youStarter: false,
      opponent: _owner,
    ));
  }

  @override
  Future<void> close() => _client.close();
}
