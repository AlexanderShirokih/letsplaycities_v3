part of 'avatar_bloc.dart';

/// States for [AvatarBloc]
abstract class AvatarState extends Equatable {
  const AvatarState();
}

/// Default avatar state
class AvatarInitial extends AvatarState {
  @override
  List<Object> get props => [];
}

/// State used when avatar changing or deleting
class AvatarLoadingState extends AvatarState {
  @override
  List<Object> get props => [];
}

/// State used when some actions is done
class AvatarDoneState extends AvatarState {
  @override
  List<Object> get props => [];
}
