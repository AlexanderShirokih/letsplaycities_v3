part of 'login_bloc.dart';

/// Login events for [LoginBloc]
abstract class LoginEvent extends Equatable {
  const LoginEvent();
}

/// Starts sign in or sign up sequence using native
class LoginNativeEvent extends LoginEvent {
  final String login;

  const LoginNativeEvent(this.login);

  @override
  List<Object> get props => [login];
}

/// Starts sign-in or sign-up sequence using social networks
class LoginSocialEvent extends LoginEvent {
  final AuthType authType;

  const LoginSocialEvent(this.authType);

  @override
  List<Object> get props => [authType];
}

/// A class used to signal that some unexpected error happens
class LoginAuthErrorEvent extends LoginEvent {
  final Object error;

  const LoginAuthErrorEvent(this.error);

  @override
  List<Object> get props => [error];
}
