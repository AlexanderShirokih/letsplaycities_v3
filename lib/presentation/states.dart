import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/data/exceptions/exceptions.dart';

/// Base state for all kinds of states
abstract class BaseState<Data> {
  const BaseState();
}

/// State used when no data available and loading not started yet
class InitialState<Data> extends BaseState<Data> {
  const InitialState();
}

/// State used while loading
class LoadingState<Data> extends BaseState<Data> with EquatableMixin {
  /// Defines progress value when no progress information available
  static const int intermediateProgress = -1;

  /// Loading progress.
  final int progress;

  /// Creates loading state with progress params
  const LoadingState({
    int? progress,
  }) : progress = progress ?? intermediateProgress;

  @override
  List<Object?> get props => [progress];
}

/// State used when data was fetched successfully
class DataState<Data> extends BaseState<Data> with EquatableMixin {
  /// Resulting data
  final Data data;

  /// Creates new [DataState]
  const DataState(this.data);

  @override
  List<Object?> get props => [data];
}

/// State used when some error happens
class ErrorState<Data> extends BaseState<Data> with EquatableMixin {
  /// Describes error reason
  final BaseException exception;

  /// Constructs new [ErrorState]
  const ErrorState(this.exception);

  @override
  List<Object?> get props => [exception];
}
