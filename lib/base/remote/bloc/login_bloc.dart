import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/remote/social/social_networks_service.dart';
import 'package:lets_play_cities/base/bloc/sequential_event_mapping.dart';

part 'login_event.dart';

part 'login_state.dart';

/// Handle user sign up events
class LoginBloc extends Bloc<LoginEvent, LoginState>
    with SequentialEventMapping<LoginEvent, LoginState> {
  final GamePreferences _preferences;
  final AccountManager _accountManager;
  final CloudMessagingService _cloudServices;
  final SocialNetworksService _socialNetworksService;

  /// Called once a social sign-up succeeds, so the caller decides which
  /// factory is current when the picture is uploaded.
  final ApiRepositoryFactory Function() _apiRepositories;

  LoginBloc({
    required this._socialNetworksService,
    required this._accountManager,
    required this._preferences,
    required this._cloudServices,
    required this._apiRepositories,
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
      yield* _handleNativeLogin(event.login);
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
      authType: AuthType.native,
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
      await _apiRepositories()
          .forCredential(remoteAccount.credential)
          .updatePictureFromURL(result.pictureUri);

      yield LoginAuthCompletedState();
    } on AuthorizationException catch (e) {
      yield LoginAuthErrorState(e);
    }
  }
}
