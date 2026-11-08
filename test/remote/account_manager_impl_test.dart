import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

import 'fake_lps_api_client.dart';

class _FakePreferences extends Fake implements GamePreferences {
  @override
  Credential? currentCredentials;

  @override
  bool get onlineChatEnabled => true;

  @override
  Future setCurrentCredentials(Credential? newCredentials) async =>
      currentCredentials = newCredentials;
}

/// Builds everything on [client] and records the credentials it was asked
/// for.
class _FakeApiRepositoryFactory extends Fake implements ApiRepositoryFactory {
  _FakeApiRepositoryFactory(this.client);

  final FakeLpsApiClient client;

  @override
  final cache = ApiRepositoryCacheHolder();

  @override
  final serverConfig = AppConfig.forHost('main.test');

  final repositoryCredentials = <Credential>[];
  final clientCredentials = <Credential>[];

  @override
  ApiRepository forCredential(Credential credential) {
    repositoryCredentials.add(credential);
    return ApiRepository(client, cache, Dio());
  }

  @override
  LpsApiClient clientFor(Credential credential) {
    clientCredentials.add(credential);
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

  group('getLastSignedInAccount', () {
    test('fetches the profile as the stored account', () async {
      const stored = Credential(userId: 1, accessToken: 'a');
      preferences.currentCredentials = stored;

      final account = await accountManager.getLastSignedInAccount();

      expect(account?.credential, stored);
      expect(apiRepositories.repositoryCredentials, [stored]);
      expect(client.profileInfoCalls, [1]);
    });

    test('asks nothing from the server when nobody is signed in', () async {
      expect(await accountManager.getLastSignedInAccount(), isNull);
      expect(apiRepositories.repositoryCredentials, isEmpty);
    });

    test('fetches again after a failed fetch', () async {
      preferences.currentCredentials = Credential(userId: 1, accessToken: 'a');
      client.onGetProfileInfo = (_) => throw _offline;

      await expectLater(
        accountManager.getLastSignedInAccount(),
        throwsA(isA<FetchingException>()),
      );

      client.onGetProfileInfo = (id) => profile(id, login: 'restored');
      final account = await accountManager.getLastSignedInAccount();

      expect(account?.name, 'restored');
      expect(client.profileInfoCalls, [1, 1]);
    });

    test('reuses a successful fetch', () async {
      preferences.currentCredentials = Credential(userId: 1, accessToken: 'a');

      await accountManager.getLastSignedInAccount();
      await accountManager.getLastSignedInAccount();

      expect(client.profileInfoCalls, [1]);
    });
  });

  group('signUp', () {
    test('signs up without credentials and stores the new ones', () async {
      preferences.currentCredentials = Credential(userId: 1, accessToken: 'a');
      client.onSignUp = (data) async => RemoteSignUpResponse(
        userId: 5,
        login: data.login,
        accessToken: 'new-token',
        pictureHash: 'hash',
        role: Role.regular,
        authType: AuthType.native,
      );

      final account = await accountManager.signUp(_signUpData('new'));

      expect(apiRepositories.clientCredentials, [const Credential.empty()]);
      expect(
        preferences.currentCredentials,
        const Credential(userId: 5, accessToken: 'new-token'),
      );
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
      expect(account.credential.userId, 2);
      expect(preferences.currentCredentials?.userId, 2);
    });

    test('replaces an account cached by getLastSignedInAccount', () async {
      preferences.currentCredentials = Credential(userId: 1, accessToken: 'a');
      await accountManager.getLastSignedInAccount();
      client.onSignUp = (data) async => signUpResponse(7, login: data.login);

      final signedUp = await accountManager.signUp(_signUpData('new'));
      final lastSignedIn = await accountManager.getLastSignedInAccount();

      expect(signedUp.credential.userId, 7);
      expect(lastSignedIn?.credential.userId, 7);
    });
  });

  group('API cache of the previous account', () {
    setUp(() {
      preferences.currentCredentials = Credential(userId: 1, accessToken: 'a');
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

      expect(preferences.currentCredentials, isNull);
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
      expect(preferences.currentCredentials?.userId, 1);
    });
  });
}
