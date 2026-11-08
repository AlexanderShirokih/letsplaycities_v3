import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/login_bloc.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';

RemoteAccount _account(String name) => RemoteAccount(
  LpsUser(
    id: 1,
    name: name,
    provider: 'native',
    lastSeenAt: DateTime(2026, 11, 8),
  ),
);

/// Answers every sign-in with [result] and records the calls.
class _FakeAccountManager extends Fake implements AccountManager {
  _FakeAccountManager(this.result);

  final Future<RemoteAccount> Function() result;
  final calls = <String>[];

  @override
  Future<RemoteAccount> signInNative(String name) {
    calls.add('native($name)');
    return result();
  }

  @override
  Future<RemoteAccount> signInSocial(AuthType type) {
    calls.add('social(${type.name})');
    return result();
  }
}

/// Holds every sign-in until the test completes [result].
class _PendingAccountManager extends Fake implements AccountManager {
  final started = Completer<void>();
  final result = Completer<RemoteAccount>();

  @override
  Future<RemoteAccount> signInSocial(AuthType type) {
    started.complete();
    return result.future;
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

class _CountingLoginBloc extends LoginBloc {
  int errorCount = 0;

  _CountingLoginBloc(AccountManager accountManager)
    : super(
        accountManager: accountManager,
        preferences: _FakePreferences(),
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
  late _FakePreferences preferences;
  late _RecordingAchievements achievements;

  setUp(() {
    preferences = _FakePreferences();
    achievements = _RecordingAchievements();
  });

  LoginBloc createBloc(AccountManager accountManager) => LoginBloc(
    accountManager: accountManager,
    preferences: preferences,
    achievements: achievements,
  );

  test('native sign-in remembers the server name and completes', () async {
    final accountManager = _FakeAccountManager(
      () async => _account('server name'),
    );
    final bloc = createBloc(accountManager);
    addTearDown(bloc.close);

    bloc.add(const LoginNativeEvent('typed name'));

    await expectLater(
      bloc.stream,
      emitsInOrder([LoginAuthenticatingState(), LoginAuthCompletedState()]),
    );
    expect(accountManager.calls, ['native(typed name)']);
    expect(preferences.lastNativeLoginWrites, ['server name']);
  });

  test('login bloc unlocks loginViaSocial only for social', () async {
    final accountManager = _FakeAccountManager(() async => _account('Alice'));
    final bloc = createBloc(accountManager);
    addTearDown(bloc.close);

    bloc
      ..add(const LoginNativeEvent('Alice'))
      ..add(const LoginSocialEvent(AuthType.vkontakte));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        LoginAuthenticatingState(),
        LoginAuthCompletedState(),
        LoginAuthenticatingState(),
        LoginAuthCompletedState(),
      ]),
    );
    expect(accountManager.calls, ['native(Alice)', 'social(vkontakte)']);
    expect(achievements.unlocked, [Achievement.loginViaSocial]);
    expect(preferences.lastNativeLoginWrites, ['Alice']);
  });

  test('a server error is reported with its code', () async {
    const error = ApiException(400, 'forbidden_name', 'Нельзя');
    final bloc = createBloc(_FakeAccountManager(() async => throw error));
    addTearDown(bloc.close);

    bloc.add(const LoginNativeEvent('typed name'));

    await expectLater(
      bloc.stream,
      emitsInOrder([LoginAuthenticatingState(), const LoginErrorState(error)]),
    );
    expect(preferences.lastNativeLoginWrites, isEmpty);
  });

  test('a failed network authorization is reported apart', () async {
    final error = AuthorizationException('cancelled');
    final bloc = createBloc(_FakeAccountManager(() async => throw error));
    addTearDown(bloc.close);

    bloc.add(const LoginSocialEvent(AuthType.google));

    await expectLater(
      bloc.stream,
      emitsInOrder([LoginAuthenticatingState(), LoginAuthErrorState(error)]),
    );
    expect(achievements.unlocked, isEmpty);
  });

  test('an unexpected error becomes LoginErrorState', () async {
    final error = StateError('broken');
    final bloc = createBloc(_FakeAccountManager(() async => throw error));
    addTearDown(bloc.close);

    bloc.add(const LoginSocialEvent(AuthType.google));

    await expectLater(
      bloc.stream,
      emitsInOrder([LoginAuthenticatingState(), LoginErrorState(error)]),
    );
    expect(achievements.unlocked, isEmpty);
  });

  test(
    'a sign-in failure after close() is reported once and not re-added',
    () async {
      final uncaught = <Object>[];
      late _CountingLoginBloc bloc;

      // Everything is created inside the guarded zone: a future does not
      // deliver its error into a different error zone.
      await runZonedGuarded(() async {
        final accountManager = _PendingAccountManager();

        bloc = _CountingLoginBloc(accountManager);
        bloc.add(const LoginSocialEvent(AuthType.google));
        await accountManager.started.future;

        // The user leaves the login screen while the request is running.
        final closing = bloc.close();
        accountManager.result.completeError(StateError('offline'));
        await closing;
        await pumpEventQueue();
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(bloc.errorCount, 1);
    },
  );
}
