import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lets_play_cities/base/users.dart';

/// Holds the game before each move until the next player takes the phone.
///
/// Used in a game of two players on one device: the timer and the move start
/// only after [release].
class TurnGate {
  final _waiting = ValueNotifier<User?>(null);

  Completer<void>? _pending;
  bool _cancelled = false;

  /// The user the game waits for, `null` while no move is held
  ValueListenable<User?> get waiting => _waiting;

  /// Completes when [next] may begin the move: after one [release], or at
  /// once when the gate is cancelled.
  Future<void> waitFor(User next) {
    if (_cancelled) return Future.value();

    final pending = Completer<void>();
    _pending = pending;
    _waiting.value = next;

    return pending.future;
  }

  /// Lets the waiting user move. Does nothing when no one waits, so a second
  /// tap does not open the gate for the next move.
  void release() {
    final pending = _pending;
    if (pending == null) return;

    _pending = null;
    _waiting.value = null;
    pending.complete();
  }

  /// Ends the wait without a move; the game no longer stops here.
  void cancel() {
    _cancelled = true;
    release();
  }
}
