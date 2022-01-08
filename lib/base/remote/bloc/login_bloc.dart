import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';

part 'login_event.dart';

part 'login_state.dart';

/// Handle user sign up events
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final GamePreferences _preferences;
  final AccountManager _accountManager;
  final CloudMessagingService _cloudServices;
  final SocialNetworksService _socialNetworksService;

  LoginBloc(
    this._socialNetworksService,
  )   : _accountManager = GetIt.instance.get<AccountManager>(),
        _preferences = GetIt.instance.get<GamePreferences>(),
        _cloudServices = GetIt.instance.get<CloudMessagingService>(),
        super(LoginInitial());

  @override
  void onError(Object error, StackTrace stackTrace) {
    add(LoginAuthErrorEvent(error));
    super.onError(error, stackTrace);
  }

  @override
  Stream<LoginState> mapEventToState(LoginEvent event) async* {
    if (event is LoginNativeEvent) {
      yield* _handleNativeLogin(event.login).map((event) {
        print("GOT EVENTTTT: $event");
        return event;
      });
    } else if (event is LoginSocialEvent) {
      yield* _handleSocialLogin(event.authType);
    } else if (event is LoginAuthErrorEvent) {
      yield LoginErrorState(event.error);
    }
  }

  Stream<LoginState> _handleNativeLogin(String login) async* {
    yield LoginAuthenticatingState();

    final request = RemoteSignUpData(
      login: login,
      authType: AuthType.Native,
      firebaseToken: await _cloudServices.getUserToken(),
      accessToken: 'native_access',
      snUID: await _socialNetworksService.getDeviceId(),
    );

    try {
      final remoteAccount = await _accountManager.signUp(request);

      _preferences.lastNativeLogin = remoteAccount.name;

      yield LoginAuthCompletedState();
    } on RemoteException catch (e) {
      yield LoginErrorState(e);
    }
  }

  Stream<LoginState> _handleSocialLogin(AuthType authType) async* {
    yield LoginAuthenticatingState();

    try {
      final result = await _socialNetworksService.login(authType);

      final request = RemoteSignUpData(
        login: result.login,
        authType: result.authType,
        firebaseToken: await _cloudServices.getUserToken(),
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
