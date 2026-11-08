import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

import 'fake_lps_api_client.dart';

class _FakePreferences extends Fake implements GamePreferences {
  @override
  bool get onlineChatEnabled => true;
}

/// Builds everything on [client] and counts the clients it was asked for.
class _FakeApiRepositoryFactory extends Fake implements ApiRepositoryFactory {
  _FakeApiRepositoryFactory(this.client);

  final FakeLpsApiClient client;

  @override
  final cache = ApiRepositoryCacheHolder();

  @override
  final serverConfig = AppConfig.forHost('main.test', port: 8443);

  @override
  final tokens = MemoryTokenStore();

  var clientRequests = 0;

  @override
  LpsApiClient clientFor([int userId = 0]) {
    clientRequests++;
    return client;
  }
}

RemoteSignUpData _signUpData(String login) => RemoteSignUpData(
  login: login,
  authType: AuthType.native,
  firebaseToken: '',
  accessToken: 'native_access',
  snUID: '',
);

final _offline = FetchingException('offline', Uri.parse('https://test/'));

void main() {
  late FakeLpsApiClient client;
  late _FakePreferences preferences;
  late _FakeApiRepositoryFactory apiRepositories;
  late ApiRepositoryCacheHolder cache;
  late AccountManagerImpl accountManager;

  setUp(() {
    client = FakeLpsApiClient();
    preferences = _FakePreferences();
    apiRepositories = _FakeApiRepositoryFactory(client);
    cache = apiRepositories.cache;
    accountManager = AccountManagerImpl(preferences, apiRepositories);
  });

  // replaced in protocol v1 task 2: the account comes from `GET /v1/me`
  test(
    'nobody is signed in until the account is loaded from the server',
    () async {
      await apiRepositories.tokens.write('stored');

      expect(await accountManager.getLastSignedInAccount(), isNull);
      expect(client.profileInfoCalls, isEmpty);
    },
  );

  group('signUp', () {
    test('stores the token of the new account', () async {
      await apiRepositories.tokens.write('old');
      client.onSignUp = (data) async => RemoteSignUpResponse(
        userId: 5,
        login: data.login,
        accessToken: 'new-token',
        pictureHash: 'hash',
        role: Role.regular,
        authType: AuthType.native,
      );

      final account = await accountManager.signUp(_signUpData('new'));

      expect(account.userId, 5);
      expect(await apiRepositories.tokens.read(), 'new-token');
      expect(
        (account.picture as NetworkPictureSource).pictureURL,
        'https://main.test:8443/user/5/picture?hash=hash',
      );
    });

    test('sends a new request after a failed sign-up', () async {
      client.onSignUp = (_) => Future.error(_offline);

      await expectLater(
        accountManager.signUp(_signUpData('first')),
        throwsA(isA<FetchingException>()),
      );

      client.onSignUp = (data) async => signUpResponse(2, login: data.login);
      final account = await accountManager.signUp(_signUpData('second'));

      expect(account.name, 'second');
      expect(client.signUpCalls, 2);
    });

    test('signs up again instead of returning the previous account', () async {
      client.onSignUp = (data) async =>
          signUpResponse(client.signUpCalls, login: data.login);

      await accountManager.signUp(_signUpData('first'));
      final account = await accountManager.signUp(_signUpData('second'));

      expect(account.name, 'second');
      expect(account.userId, 2);
    });
  });

  group('API cache of the previous account', () {
    setUp(() async {
      await apiRepositories.tokens.write('a');
      cache.cachedFriendsList = [friend(10)];
      cache.cachedBanList = [banned(11)];
      cache.cachedProfilesInfo.put(
        profile(1, friendshipStatus: FriendshipStatus.owner),
      );
    });

    void expectCacheCleared() {
      expect(cache.cachedFriendsList, isNull);
      expect(cache.cachedBanList, isNull);
      expect(cache.cachedProfilesInfo.get((_) => true), isNull);
    }

    test('is cleared on sign-out', () async {
      await accountManager.signOut();

      expect(await apiRepositories.tokens.read(), isNull);
      expectCacheCleared();
    });

    test('is cleared on a successful sign-up', () async {
      client.onSignUp = (data) async => signUpResponse(2, login: data.login);

      await accountManager.signUp(_signUpData('other'));

      expectCacheCleared();
    });

    test('is kept when the sign-up fails', () async {
      client.onSignUp = (_) => Future.error(_offline);

      await expectLater(
        accountManager.signUp(_signUpData('other')),
        throwsA(isA<FetchingException>()),
      );

      expect(cache.cachedFriendsList, isNotEmpty);
      expect(await apiRepositories.tokens.read(), 'a');
    });
  });
}
