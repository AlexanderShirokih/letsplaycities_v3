import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/achievements/achievements.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';

part 'login_event.dart';

part 'login_state.dart';

/// Signs the user in by the events of the login screen
class LoginBloc extends Bloc<LoginEvent, LoginState>
    with SequentialEventMapping<LoginEvent, LoginState> {
  final GamePreferences _preferences;
  final AccountManager _accountManager;
  final AchievementsService _achievements;

  LoginBloc({
    required this._accountManager,
    required this._preferences,
    required this._achievements,
  }) : super(LoginInitial()) {
    mapEventsSequentially(_mapEventToState);
  }

  /// Set as soon as [close] starts. [isClosed] only covers the event queue
  /// from bloc 9.2.1 on, and pubspec.yaml does not pin that version.
  bool _closing = false;

  @override
  Future<void> close() {
    _closing = true;
    return super.close();
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    // After close() add() throws StateError and reports it through onError,
    // so an unguarded add() here recurses until the stack overflows.
    if (!_closing) add(LoginAuthErrorEvent(error));
    super.onError(error, stackTrace);
  }

  Stream<LoginState> _mapEventToState(LoginEvent event) async* {
    if (event is LoginNativeEvent) {
      yield* _signIn(() async {
        final account = await _accountManager.signInNative(event.login);
        _preferences.lastNativeLogin = account.name;
      });
    } else if (event is LoginSocialEvent) {
      yield* _signIn(() async {
        await _accountManager.signInSocial(event.authType);
        await _achievements.unlockAchievement(Achievement.loginViaSocial);
      });
    } else if (event is LoginAuthErrorEvent) {
      yield LoginErrorState(event.error);
    }
  }

  Stream<LoginState> _signIn(Future<void> Function() signIn) async* {
    yield LoginAuthenticatingState();

    try {
      await signIn();

      yield LoginAuthCompletedState();
    } on ApiException catch (e) {
      yield LoginErrorState(e);
    } on AuthorizationException catch (e) {
      yield LoginAuthErrorState(e);
    }
  }
}
