/// Base class for async single param use case
abstract class SingleAsyncUseCase<Param, Result> {
  /// Executes use case with given [request]
  Future<Result> execute(Param request);
}

/// Base class for two params async use case
abstract class PairedAsyncUseCase<Param1, Param2, Result> {
  Future<Result> execute(Param1 param1, Param2 param2);
}

/// Base class for single param use case
abstract class SingleUseCase<Param, Result> {
  /// Executes use case with given [request]
  Result execute(Param request);
}

/// Base class for two params use case
abstract class PairedUseCase<Param1, Param2, Result> {
  Result execute(Param1 param1, Param2 param2);
}
