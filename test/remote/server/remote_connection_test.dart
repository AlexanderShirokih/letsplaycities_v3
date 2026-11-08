import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/client_messages.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/server/connection_transformer.dart';
import 'package:lets_play_cities/remote/server/remote_connection.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import 'remote_connection_test.mocks.dart';
import 'server_mocks.dart';

@GenerateNiceMocks([
  MockSpec<MessagePipe<ClientMessage, ServerMessage>>(as: #MockMessagePipe),
  MockSpec<UserLookupRepository>(),
])
void main() {
  late MockMessagePipe messagePipe;
  late MockUserLookupRepository lookupRepository;
  late RemoteConnection serverInteractor;

  setUp(() {
    messagePipe = MockMessagePipe();
    lookupRepository = MockUserLookupRepository();
    serverInteractor = LpsServerInteractorImpl(messagePipe, lookupRepository);
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
        authType: AuthType.native,
      ),
    );

    when(messagePipe.readMessage()).thenAnswer(
      (_) async => LogInMessage(
        clientBuild: 123,
        clientVersion: '1.2.3',
        canReceiveMessages: true,
        firebaseToken: 'fbToken',
        uid: expectedUserId,
        hash: 'hash',
      ),
    );

    await expectLater(serverInteractor.authorize(), completes);

    verify(messagePipe.sendMessage(captureThat(isA<LoggedInMessage>())))
        .called(1);
  });

  test('await start should return JoinMessage with owner', () async {
    when(messagePipe.readMessage()).thenAnswer(
      (_) async => PlayMessage(mode: PlayMode.randomPair, oppUid: null),
    );

    await expectLater(serverInteractor.ready, completes);

    await serverInteractor.join(
      canReceiveMessages: true,
      youStarter: false,
      opponent: testProfile,
    );

    final captured = verify(
      messagePipe.sendMessage(captureThat(isA<JoinMessage>())),
    ).captured.cast<JoinMessage>();

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
      WordResult.received,
      'city',
      BaseProfileInfo(userId: 123, login: 'hello'),
    );

    final captures = verify(
      messagePipe.sendMessage(captureThat(isA<WordMessage>())),
    ).captured.cast<WordMessage>();

    expect(captures.length, equals(1));
    expect(captures.single.ownerId, equals(123));
    expect(captures.single.word, equals('city'));
    expect(captures.single.result, equals(WordResult.received));

    verifyNoMoreInteractions(messagePipe);
  });

  test('Interactor passes chat messages to message pipe', () async {
    serverInteractor.sendMessage(
      'hello world',
      BaseProfileInfo(userId: 123, login: 'test'),
    );

    final captures = verify(
      messagePipe.sendMessage(captureThat(isA<ChatMessage>())),
    ).captured.cast<ChatMessage>();

    expect(captures.length, equals(1));
    expect(captures.single.ownerId, equals(123));
    expect(captures.single.message, equals('hello world'));

    verifyNoMoreInteractions(messagePipe);
  });
}
