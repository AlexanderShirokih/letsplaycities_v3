import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/server/local_account_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'local_account_manager_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GamePreferences>(),
  MockSpec<RemoteSignUpData>(),
  MockSpec<SingleAsyncUseCase<RemoteSignUpData, RemoteSignUpResponse>>(
      as: #MockSignUp),
  MockSpec<AccountManager>(),
])

void main() {
  late AccountManager accountManager;
  late RemoteSignUpData signUpData;
  late GamePreferences gamePreferences;
  late AccountManager mainAccountManager;
  late MockSignUp signUp;

  setUp(() {
    signUp = MockSignUp();
    signUpData = MockRemoteSignUpData();
    gamePreferences = MockGamePreferences();
    mainAccountManager = MockAccountManager();
    accountManager = LocalAccountManager(
      mainAccountManager,
      gamePreferences,
      signUp,
    );

    when(mainAccountManager.getLastSignedInAccount())
        .thenAnswer((_) async => null);
  });

  test('Sign out completes', () async {
    await expectLater(accountManager.signOut(), completes);
  });

  test('Sign Up throws an error, cause it is unsupported on local games',
      () async {
    await expectLater(() => accountManager.signUp(signUpData),
        throwsA(isA<RemoteException>()));

    verifyNoMoreInteractions(signUpData);
  });

  test('Uses main account manager if it returns non null value', () async {
    when(signUp.execute(any)).thenAnswer((inv) {
      final signUpData = inv.positionalArguments[0] as RemoteSignUpData;
      return Future.value(
        RemoteSignUpResponse(
          accessToken: signUpData.accessToken,
          login: signUpData.login,
          authType: AuthType.Native,
          role: Role.regular,
          userId: 1234,
          pictureHash: '',
        ),
      );
    });
    when(gamePreferences.onlineChatEnabled).thenReturn(true);
    when(gamePreferences.lastNativeLogin).thenReturn('test');

    // The stub must produce a Future<RemoteAccount?> just like the real
    // implementation, otherwise `.timeout(onTimeout: () => null)` fails.
    when(mainAccountManager.getLastSignedInAccount())
        .thenAnswer((_) async => RemoteAccount(
              credential: Credential(userId: 4321, accessToken: 'tkn'),
              name: 'test_remote',
              canReceiveMessages: false,
              role: Role.regular,
              authType: AuthType.Native,
              pictureUri: 'http://test',
            ) as RemoteAccount?);

    final result = (await accountManager.getLastSignedInAccount())!;

    verify(mainAccountManager.getLastSignedInAccount()).called(1);
    verify(signUp.execute(any)).called(1);

    expect(result.credential.accessToken, equals('native_access'));
    expect(result.credential.userId, equals(1234));
    expect(result.authType, equals(AuthType.Native));
    expect(result.name, equals('test_remote'));
    expect(result.canReceiveMessages, isTrue);
  });

  test('getLastSignedInAccount() returns valid data', () async {
    final response = RemoteSignUpResponse(
      accessToken: 'accToken',
      login: 'responseLogin',
      authType: AuthType.Native,
      role: Role.regular,
      userId: 1234,
      pictureHash: '',
    );

    when(signUp.execute(any)).thenAnswer((_) => Future.value(response));
    when(gamePreferences.onlineChatEnabled).thenReturn(true);
    when(gamePreferences.lastNativeLogin).thenReturn('test');

    final result = (await accountManager.getLastSignedInAccount())!;

    verify(signUp.execute(any)).called(1);

    expect(result.credential.accessToken, equals(response.accessToken));
    expect(result.credential.userId, equals(response.userId));
    expect(result.authType, equals(response.authType));
    expect(result.name, equals(response.login));
    expect(result.canReceiveMessages, isTrue);
  });
}
