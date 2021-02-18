//@dart=2.9

import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/server/local_account_manager.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class _MockGamePreferences extends Mock implements GamePreferences {}

class _MockRemoteSignUpData extends Mock implements RemoteSignUpData {}

class _MockApiClient extends Mock implements LpsApiClient {}

void main() {
  AccountManager accountManager;
  RemoteSignUpData signUpData;
  GamePreferences gamePreferences;
  LpsApiClient apiClient;

  setUp(() {
    apiClient = _MockApiClient();
    signUpData = _MockRemoteSignUpData();
    gamePreferences = _MockGamePreferences();
    accountManager = LocalAccountManager(gamePreferences, apiClient);
  });

  test('Sign out completes', () async {
    await expectLater(accountManager.signOut(), completes);
  });

  test('Sign Up throws an error, cause it is unsupported on local games',
      () async {
    await expectLater(() => accountManager.signUp(signUpData),
        throwsA(isA<RemoteException>()));

    verifyZeroInteractions(signUpData);
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

    when(apiClient.signUp(any)).thenAnswer((_) => Future.value(response));
    when(gamePreferences.onlineChatEnabled).thenReturn(true);
    when(gamePreferences.lastNativeLogin).thenReturn('test');

    final result = await accountManager.getLastSignedInAccount();

    verify(apiClient.signUp(any)).called(1);

    expect(result.credential.accessToken, equals(response.accessToken));
    expect(result.credential.userId, equals(response.userId));
    expect(result.authType, equals(response.authType));
    expect(result.name, equals(response.login));
    expect(result.canReceiveMessages, isTrue);
  });
}
