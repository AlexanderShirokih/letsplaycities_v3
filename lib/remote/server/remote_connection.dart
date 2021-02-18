import 'package:lets_play_cities/base/data/word_result.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';

import 'user_lookup_repository.dart';

/// Handles LPS protocol interactions with particular client
abstract class RemoteConnection {
  /// Factory constructor that creates default implementation
  factory RemoteConnection.fromMessagePipe(
    MessagePipe<ClientMessage, ServerMessage> pipe,
    UserLookupRepository userLookupRepository,
  ) =>
      LpsServerInteractorImpl(pipe, userLookupRepository);

  /// Returns [ProfileInfo] of [RemoteConnection] owner
  ProfileInfo get profile;

  /// Authorizes client on the server. Returns `null` if user cannot be authorized
  Future<ProfileInfo?> authorize();

  /// Returns [Future] that completes when 'Play' message received
  /// Throws [RemoteException] if requested play mode isn't [PlayMode.RANDOM_PAIR]
  Future<void> get ready;

  /// Closes current connection
  Future<void> close();

  /// Sends word to the client
  void sendWord(WordResult wordResult, String city, BaseProfileInfo owner);

  /// Sends chat message to the client
  void sendMessage(String message, BaseProfileInfo owner);

  /// Stream of incoming messages by this user
  Stream<String> get incomingMessages;

  /// Stream of incoming words by this user
  Stream<String> get incomingWords;

  /// Sends join message to the client
  Future<void> join({
    required bool canReceiveMessages,
    required bool youStarter,
    required ProfileInfo opponent,
  });
}

/// Implementation of [RemoteConnection]
class LpsServerInteractorImpl implements RemoteConnection {
  final MessagePipe<ClientMessage, ServerMessage> _client;
  final UserLookupRepository _userLookupRepository;

  ProfileInfo? _authorizedProfile;

  @override
  ProfileInfo get profile {
    if (_authorizedProfile == null) {
      throw StateError('User is unauthorized yet!');
    } else {
      return _authorizedProfile!;
    }
  }

  LpsServerInteractorImpl(this._client, this._userLookupRepository);

  @override
  Future<ProfileInfo?> authorize() async {
    final loginRequest = await _client.readMessage() as LogInMessage;
    final version = loginRequest.version;

    if (5 != version) {
      throw RemoteException(
          'Incompatible protocol versions(5 != $version)! Please, upgrade your application');
    }

    final profileInfo = _userLookupRepository.getUser(
      Credential(
        userId: loginRequest.uid,
        accessToken: loginRequest.hash,
      ),
    );

    if (profileInfo == null) {
      _client.sendMessage(
        BannedMessage(banReason: 'Credentials was not found!'),
      );
      return null;
    }

    _authorizedProfile = profileInfo;

    _client.sendMessage(LoggedInMessage(newerBuild: 1));

    return profileInfo;
  }

  @override
  Future<void> close() => _client.close();

  @override
  void sendWord(WordResult wordResult, String city, BaseProfileInfo owner) =>
      _client.sendMessage(WordMessage(
        result: wordResult,
        word: city,
        ownerId: owner.userId,
      ));

  @override
  void sendMessage(String message, BaseProfileInfo owner) =>
      _client.sendMessage(ChatMessage(
        message: message,
        ownerId: owner.userId,
      ));

  @override
  Future<void> get ready async {
    final playRequest = (await _client.readMessage()) as PlayMessage;

    if (playRequest.mode != PlayMode.RANDOM_PAIR) {
      throw RemoteException('Protocol error: invalid play mode!');
    }
  }

  @override
  Future<void> join({
    required bool canReceiveMessages,
    required bool youStarter,
    required ProfileInfo opponent,
  }) async =>
      _client.sendMessage(JoinMessage(
        canReceiveMessages: canReceiveMessages,
        youStarter: youStarter,
        opponent: opponent,
      ));

  @override
  Stream<String> get incomingMessages => _client
      .readAllMessages()
      .where((event) => event is OutgoingChatMessage)
      .cast<OutgoingChatMessage>()
      .map((event) => event.msg);

  @override
  Stream<String> get incomingWords => _client
      .readAllMessages()
      .where((event) => event is OutgoingWordMessage)
      .cast<OutgoingWordMessage>()
      .map((event) => event.word);
}
