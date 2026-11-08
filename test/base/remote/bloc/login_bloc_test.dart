import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/login_bloc.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/social/social_network_data.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';

import '../../../remote/fake_api_repository_factory.dart';

/// Answers every sign-up with [onSignUp] and keeps the requests it got.
class _FakeAccountManager extends Fake implements AccountManager {
  _FakeAccountManager(this.onSignUp);

  final Future<RemoteAccount> Function(RemoteSignUpData request) onSignUp;
  final requests = <RemoteSignUpData>[];

  @override
  Future<RemoteAccount> signUp(RemoteSignUpData signInData) {
    requests.add(signInData);
    return onSignUp(signInData);
  }
}

/// Holds every sign-up until the test completes [signUpResult].
class _PendingSignUpAccountManager extends Fake implements AccountManager {
  final signUpStarted = Completer<void>();
  final signUpResult = Completer<RemoteAccount>();

  @override
  Future<RemoteAccount> signUp(RemoteSignUpData signInData) {
    signUpStarted.complete();
    return signUpResult.future;
  }
}

class _FakePreferences extends Fake implements GamePreferences {
  final lastNativeLoginWrites = <String>[];

  @override
  set lastNativeLogin(String newLogin) => lastNativeLoginWrites.add(newLogin);
}

class _RecordingAchievements extends Fake implements AchievementsService {
  final unlocked = <Achievement>[];

  @override
  Future<void> unlockAchievement(
    Achievement achievement, [
    int incrementCount = 1,
  ]) async => unlocked.add(achievement);
}

class _FakeCloudMessaging extends Fake implements CloudMessagingService {
  @override
  Future<String> getUserToken() async => 'cloud-token';
}

class _FakeSocialNetworks extends Fake implements SocialNetworksService {
  /// When set, [login] throws it instead of returning a result.
  Object? loginError;

  @override
  Future<SocialNetworkData> login(AuthType networkType) async {
    if (loginError != null) throw loginError!;
    return SocialNetworkData(
      login: 'social user',
      authType: networkType,
      pictureUri: 'https://example.com/picture.png',
      accessToken: 'social-access',
      snUID: 'social-uid',
    );
  }

  @override
  Future<String> getDeviceId() async => 'device-id';
}

class _FakeApiRepository extends Fake implements ApiRepository {
  final updatedPictures = <String>[];

  @override
  Future<void> updatePictureFromURL(String pictureURL) async {
    updatedPictures.add(pictureURL);
  }
}

const _signedUpCredential = Credential(userId: 1, accessToken: 'token');

RemoteAccount _signedUpAccount(String name) => RemoteAccount(
  credential: _signedUpCredential,
  name: name,
  canReceiveMessages: false,
  role: Role.regular,
  authType: AuthType.native,
  pictureUri: null,
);

class _CountingLoginBloc extends LoginBloc {
  int errorCount = 0;

  _CountingLoginBloc(AccountManager accountManager)
    : super(
        socialNetworksService: _FakeSocialNetworks(),
        accountManager: accountManager,
        preferences: _FakePreferences(),
        cloudServices: _FakeCloudMessaging(),
        apiRepositories: () => throw StateError('No picture is uploaded'),
        achievements: _RecordingAchievements(),
      );

  @override
  void onError(Object error, StackTrace stackTrace) {
    // Breaks the onError -> add -> StateError -> onError loop after a few
    // rounds, so a regression fails the test instead of hanging the isolate.
    if (++errorCount > 5) return;
    super.onError(error, stackTrace);
  }
}

void main() {
  late _FakeApiRepository apiRepository;
  late FakeApiRepositoryFactory apiRepositories;
  late _FakePreferences preferences;
  late _FakeSocialNetworks socialNetworks;
  late _RecordingAchievements achievements;

  late int factoryLookups;

  setUp(() {
    apiRepository = _FakeApiRepository();
    apiRepositories = FakeApiRepositoryFactory(apiRepository);
    preferences = _FakePreferences();
    socialNetworks = _FakeSocialNetworks();
    achievements = _RecordingAchievements();
    factoryLookups = 0;
  });

  LoginBloc createBloc(AccountManager accountManager) => LoginBloc(
    socialNetworksService: socialNetworks,
    accountManager: accountManager,
    preferences: preferences,
    cloudServices: _FakeCloudMessaging(),
    apiRepositories: () {
      factoryLookups++;
      return apiRepositories;
    },
    achievements: achievements,
  );

  group('native login', () {
    test('signs up, remembers the login and completes', () async {
      final accountManager = _FakeAccountManager(
        (request) async => _signedUpAccount('server name'),
      );
      final bloc = createBloc(accountManager);
      addTearDown(bloc.close);

      bloc.add(const LoginNativeEvent('typed name'));

      await expectLater(
        bloc.stream,
        emitsInOrder([LoginAuthenticatingState(), LoginAuthCompletedState()]),
      );
      final request = accountManager.requests.single;
      expect(request.login, 'typed name');
      expect(request.authType, AuthType.native);
      expect(request.firebaseToken, 'cloud-token');
      expect(request.accessToken, 'native_access');
      expect(request.snUID, 'device-id');
      // The server may change the name, and its version is the one kept.
      expect(preferences.lastNativeLoginWrites, ['server name']);
      expect(factoryLookups, 0);
      expect(achievements.unlocked, isEmpty);
    });

    test('reports a server error and keeps the last login', () async {
      final error = FetchingException('offline', Uri());
      final bloc = createBloc(_FakeAccountManager((_) async => throw error));
      addTearDown(bloc.close);

      bloc.add(const LoginNativeEvent('typed name'));

      await expectLater(
        bloc.stream,
        emitsInOrder([LoginAuthenticatingState(), LoginErrorState(error)]),
      );
      expect(preferences.lastNativeLoginWrites, isEmpty);
    });
  });

  group('social login', () {
    test('signs up with the network data and updates the picture', () async {
      late int lookupsAtSignUp;
      final accountManager = _FakeAccountManager((request) async {
        lookupsAtSignUp = factoryLookups;
        return _signedUpAccount('social user');
      });
      final bloc = createBloc(accountManager);
      addTearDown(bloc.close);

      bloc.add(const LoginSocialEvent(AuthType.vkontakte));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          LoginAuthenticatingState(),
          LoginAuthUpdateAvatarState(),
          LoginAuthCompletedState(),
        ]),
      );
      final request = accountManager.requests.single;
      expect(request.login, 'social user');
      expect(request.authType, AuthType.vkontakte);
      expect(request.firebaseToken, 'cloud-token');
      expect(request.accessToken, 'social-access');
      expect(request.snUID, 'social-uid');
      expect(apiRepository.updatedPictures, [
        'https://example.com/picture.png',
      ]);
      // The picture is uploaded as the new account, through the factory
      // looked up after the sign-up.
      expect(apiRepositories.credentials, [_signedUpCredential]);
      expect(lookupsAtSignUp, 0);
      expect(factoryLookups, 1);
      expect(preferences.lastNativeLoginWrites, isEmpty);
      expect(achievements.unlocked, [Achievement.loginViaSocial]);
    });

    test('reports a failed network authorization', () async {
      final error = AuthorizationException('cancelled');
      socialNetworks.loginError = error;
      final accountManager = _FakeAccountManager(
        (request) async => _signedUpAccount('social user'),
      );
      final bloc = createBloc(accountManager);
      addTearDown(bloc.close);

      bloc.add(const LoginSocialEvent(AuthType.google));

      await expectLater(
        bloc.stream,
        emitsInOrder([LoginAuthenticatingState(), LoginAuthErrorState(error)]),
      );
      expect(accountManager.requests, isEmpty);
      expect(achievements.unlocked, isEmpty);
    });

    test('reports an unexpected sign-up error as LoginErrorState', () async {
      final error = FetchingException('offline', Uri());
      final bloc = createBloc(_FakeAccountManager((_) async => throw error));
      addTearDown(bloc.close);

      bloc.add(const LoginSocialEvent(AuthType.google));

      await expectLater(
        bloc.stream,
        emitsInOrder([LoginAuthenticatingState(), LoginErrorState(error)]),
      );
      expect(achievements.unlocked, isEmpty);
    });
  });

  test(
    'a sign-up failure after close() is reported once and not re-added',
    () async {
      final uncaught = <Object>[];
      late _CountingLoginBloc bloc;

      // Everything is created inside the guarded zone: a future does not
      // deliver its error into a different error zone.
      await runZonedGuarded(() async {
        final accountManager = _PendingSignUpAccountManager();

        bloc = _CountingLoginBloc(accountManager);
        bloc.add(const LoginSocialEvent(AuthType.google));
        await accountManager.signUpStarted.future;

        // The user leaves the login screen while the request is running.
        final closing = bloc.close();
        accountManager.signUpResult.completeError(
          FetchingException('offline', Uri()),
        );
        await closing;
        await pumpEventQueue();
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(bloc.errorCount, 1);
    },
  );
}
