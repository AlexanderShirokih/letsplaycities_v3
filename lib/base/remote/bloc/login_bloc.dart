import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';

part 'login_event.dart';

part 'login_state.dart';

/// Handle user sign up events
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final GamePreferences _preferences;

  LoginBloc(this._preferences) : super(LoginInitial());

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is LoginNativeEvent) {
      yield* _handleNativeLogin(event.login);
    } else if (event is LoginSocialEvent) {
      yield* _handleSocialLogin(event.authType);
    }
  }

  Stream<LoginState> _handleNativeLogin(String login) async* {
    yield LoginAuthenticatingState();

    _preferences.lastNativeLogin = login;
    if (login == 'test') {
      // TODO: Remove test code
      await _preferences.setCurrentCredentials(
          Credential(userId: 30955, accessToken: "i'mapass"));
      yield LoginAuthCompletedState();
      return;
    }
    // TODO: Handle native login
  }

  Stream<LoginState> _handleSocialLogin(AuthType authType) async* {
    yield LoginAuthenticatingState();

    // TODO: Handle social login
  }
}
