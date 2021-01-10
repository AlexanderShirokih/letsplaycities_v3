part of 'login_bloc.dart';

/// States for [LoginBloc]
abstract class LoginState extends Equatable {
  const LoginState();
}

/// Default state used to show login fields
class LoginInitial extends LoginState {
  @override
  List<Object> get props => [];
}

/// State used while authentication process running
class LoginAuthenticatingState extends LoginState {
  @override
  List<Object> get props => [];
}

/// State used when authentication process completed
class LoginAuthCompletedState extends LoginState {
  @override
  List<Object> get props => [];
}
