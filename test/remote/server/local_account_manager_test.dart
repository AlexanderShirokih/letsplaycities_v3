import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/server/local_account_manager.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'local_account_manager_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GamePreferences>(),
  MockSpec<RemoteSignUpData>(),
  MockSpec<SingleAsyncUseCase<RemoteSignUpData, RemoteSignUpResponse>>(
    as: #MockSignUp,
  ),
  MockSpec<AccountManager>(),
])
void main() {
  late AccountManager accountManager;
  late GamePreferences gamePreferences;
  late AccountManager mainAccountManager;
  late MockSignUp signUp;

  setUp(() {
    signUp = MockSignUp();
    gamePreferences = MockGamePreferences();
    mainAccountManager = MockAccountManager();
    accountManager = LocalAccountManager(
      mainAccountManager,
      gamePreferences,
      signUp,
      'default_login',
    );

    when(mainAccountManager.getLastSignedInAccount())
        .thenAnswer((_) async => null);
  });

  test('Sign out completes', () async {
    await expectLater(accountManager.signOut(), completes);
  });

  test(
    'Sign-ins throw an error, cause they are unsupported on local games',
    () async {
      await expectLater(
        accountManager.signInNative('name'),
        throwsA(isA<RemoteException>()),
      );
      await expectLater(
        accountManager.signInSocial(AuthType.google),
        throwsA(isA<RemoteException>()),
      );
      await expectLater(
        accountManager.trySilentNative(),
        throwsA(isA<RemoteException>()),
      );
    },
  );

  test('Uses main account manager if it returns non null value', () async {
    when(signUp.execute(any)).thenAnswer((inv) {
      final signUpData = inv.positionalArguments[0] as RemoteSignUpData;
      return Future.value(
        RemoteSignUpResponse(
          accessToken: signUpData.accessToken,
          login: signUpData.login,
          authType: AuthType.native,
          role: Role.regular,
          userId: 1234,
          pictureHash: '',
        ),
      );
    });
    when(gamePreferences.onlineChatEnabled).thenReturn(true);
    when(gamePreferences.lastNativeLogin).thenReturn('test');

    when(mainAccountManager.getLastSignedInAccount()).thenAnswer(
      (_) async => RemoteAccount(
        LpsUser(
          id: 4321,
          name: 'test_remote',
          provider: 'native',
          lastSeenAt: DateTime(2026),
        ),
        avatarUrl: 'http://test',
      ) as RemoteAccount?,
    );

    final result = (await accountManager.getLastSignedInAccount())!;

    verify(mainAccountManager.getLastSignedInAccount()).called(1);
    verify(signUp.execute(any)).called(1);

    expect(result.userId, equals(1234));
    expect(result.user.provider, equals('lan'));
    expect(result.avatarUrl, equals('http://test'));
    expect(result.name, equals('test_remote'));
    expect(result.canReceiveMessages, isTrue);
  });

  test(
    'Falls back to a native account when the main account fails to load',
    () async {
      when(signUp.execute(any)).thenAnswer((inv) {
        final signUpData = inv.positionalArguments[0] as RemoteSignUpData;
        return Future.value(
          RemoteSignUpResponse(
            accessToken: 'local_token',
            login: signUpData.login,
            authType: AuthType.native,
            role: Role.regular,
            userId: 77,
            pictureHash: '',
          ),
        );
      });
      when(gamePreferences.onlineChatEnabled).thenReturn(false);
      when(gamePreferences.lastNativeLogin).thenReturn('offline_login');
      // No internet on the local network: the profile request fails at once.
      when(mainAccountManager.getLastSignedInAccount()).thenAnswer(
        (_) => Future<RemoteAccount?>.error(
          FetchingException('No route to host', Uri.parse('https://lps')),
        ),
      );

      final result = (await accountManager.getLastSignedInAccount())!;

      final sentData =
          verify(signUp.execute(captureAny)).captured.single
              as RemoteSignUpData;
      expect(sentData.login, equals('offline_login'));
      expect(sentData.snUID, isEmpty);
      expect(result.name, equals('offline_login'));
      expect(result.userId, equals(77));
    },
  );

  test('getLastSignedInAccount() returns valid data', () async {
    final response = RemoteSignUpResponse(
      accessToken: 'accToken',
      login: 'responseLogin',
      authType: AuthType.native,
      role: Role.regular,
      userId: 1234,
      pictureHash: '',
    );

    when(signUp.execute(any)).thenAnswer((_) => Future.value(response));
    when(gamePreferences.onlineChatEnabled).thenReturn(true);
    when(gamePreferences.lastNativeLogin).thenReturn('test');

    final result = (await accountManager.getLastSignedInAccount())!;

    verify(signUp.execute(any)).called(1);

    expect(result.userId, equals(response.userId));
    expect(result.user.provider, equals('lan'));
    expect(result.name, equals(response.login));
    expect(result.canReceiveMessages, isTrue);
  });
}
