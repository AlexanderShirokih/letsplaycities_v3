// @dart=2.9

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';
import 'package:lets_play_cities/remote/server/remote_connection.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'server_mocks.dart';

class _MockMessagePipe extends Mock
    implements MessagePipe<ClientMessage, ServerMessage> {}

class _MockUserLookupRepository extends Mock implements UserLookupRepository {}

void main() {
  _MockMessagePipe messagePipe;
  _MockUserLookupRepository lookupRepository;
  RemoteConnection serverInteractor;

  setUp(() {
    messagePipe = _MockMessagePipe();
    lookupRepository = _MockUserLookupRepository();
    serverInteractor = LpsServerInteractorImpl(
      messagePipe,
      lookupRepository,
    );
  });

  test('Login works properly', () async {
    final expectedUserId = 12345;

    when(lookupRepository.getUser(any)).thenReturn(
      ProfileInfo(
        userId: 1,
        login: 'test',
        pictureUrl: '',
        role: Role.regular,
        lastVisitDate: DateTime.now(),
        banStatus: BanStatus.notBanned,
        friendshipStatus: FriendshipStatus.notFriends,
        authType: AuthType.Native,
      ),
    );

    when(messagePipe.readMessage()).thenAnswer((_) async => LogInMessage(
          clientBuild: 123,
          clientVersion: '1.2.3',
          canReceiveMessages: true,
          firebaseToken: 'fbToken',
          uid: expectedUserId,
          hash: 'hash',
        ));

    await expectLater(serverInteractor.authorize(), completes);

    verify(messagePipe.sendMessage(captureThat(isA<LoggedInMessage>())))
        .called(1);
  });

  test('await start should return JoinMessage with owner', () async {
    when(messagePipe.readMessage()).thenAnswer(
      (_) async => PlayMessage(
        mode: PlayMode.RANDOM_PAIR,
        oppUid: null,
      ),
    );

    await expectLater(serverInteractor.ready, completes);

    await serverInteractor.join(
      canReceiveMessages: true,
      youStarter: false,
      opponent: testProfile,
    );

    final captured =
        verify(messagePipe.sendMessage(captureThat(isA<JoinMessage>())))
            .captured
            .cast<JoinMessage>();

    expect(captured.length, equals(1));
    expect(captured.single.youStarter, false);
    expect(captured.single.canReceiveMessages, true);
    expect(captured.single.opponent, equals(testProfile));
  });

  test('Server interactor closes connection', () async {
    await serverInteractor.close();
    verify(messagePipe.close()).called(1);
    verifyNoMoreInteractions(messagePipe);
  });

  test('Interactor passes words to message pipe', () async {
    serverInteractor.sendWord(
      WordResult.RECEIVED,
      'city',
      BaseProfileInfo(
        userId: 123,
        login: 'hello',
      ),
    );

    final captures =
        verify(messagePipe.sendMessage(captureThat(isA<WordMessage>())))
            .captured
            .cast<WordMessage>();

    expect(captures.length, equals(1));
    expect(captures.single.ownerId, equals(123));
    expect(captures.single.word, equals('city'));
    expect(captures.single.result, equals(WordResult.RECEIVED));

    verifyNoMoreInteractions(messagePipe);
  });

  test('Interactor passes chat messages to message pipe', () async {
    serverInteractor.sendMessage(
      'hello world',
      BaseProfileInfo(
        userId: 123,
        login: 'test',
      ),
    );

    final captures =
        verify(messagePipe.sendMessage(captureThat(isA<ChatMessage>())))
            .captured
            .cast<ChatMessage>();

    expect(captures.length, equals(1));
    expect(captures.single.ownerId, equals(123));
    expect(captures.single.message, equals('hello world'));

    verifyNoMoreInteractions(messagePipe);
  });
}
