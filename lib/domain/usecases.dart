/// Base class for single param use case
abstract class SingleAsyncUseCase<Param, Result> {
  /// Executes use case with given [request]
  Future<Result> execute(Param request);
}

/// Base class for two params use case
abstract class PairedAsyncUseCase<Param1, Param2, Result> {
  Future<Result> execute(Param1 param1, Param2 param2);
}
