import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/firebase/firebase_service.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';

part 'login_event.dart';

part 'login_state.dart';

/// Handle user sign up events
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final GamePreferences _preferences;
  final AccountManager _accountManager;
  final FirebaseServices _firebaseServices;
  final SocialNetworksService _socialNetworksService;

  LoginBloc(
    this._preferences,
    this._firebaseServices,
    this._socialNetworksService,
  )   : _accountManager = AccountManager.fromPreferences(_preferences),
        super(LoginInitial());

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

    try {
      final result = await _socialNetworksService.login(authType);
      final request = RemoteSignUpData(
        login: result.login,
        authType: result.authType,
        firebaseToken: await _firebaseServices.getToken(),
        accessToken: result.accessToken,
        snUID: result.snUID,
      );

      final remoteAccount = await _accountManager.signUp(request);

      yield LoginAuthUpdateAvatarState();
      await remoteAccount
          .getApiRepository()
          .updatePictureFromURL(result.pictureUri);

      yield LoginAuthCompletedState();
    } on AuthorizationException catch (e) {
      yield LoginAuthErrorState(e);
    }
  }
}
