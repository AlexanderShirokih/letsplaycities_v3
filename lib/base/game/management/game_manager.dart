import 'dart:async';

abstract class BaseGameManager {
  final Function _timeLimitSupplier;

  BaseGameManager(this._timeLimitSupplier);

  /// Returns game timer, that ticks every second and completes when time is out.
  /// If [timeLimitSupplier] returns `0` timer won't emit any event
  Stream<int> getTimer() {
    int timeLimit = _timeLimitSupplier();
    if (timeLimit <= 0) return Stream<int>.empty();

    return Stream.periodic(Duration(seconds: 1), (currentTick) => currentTick)
        .take(timeLimit + 1)
        .map((tick) => timeLimit - tick);
  }

  /// Triggers when player was banned.
  /// `true` means that player was banned by system and `false` is that it was banned by opponent.
  Future<bool> getKicks() => Future.value(null);
}
