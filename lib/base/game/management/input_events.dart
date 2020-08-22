import 'package:meta/meta.dart';

@sealed
abstract class InputEvent {}

@sealed
abstract class InputGameEvent extends InputEvent {
  final int ownerId;

  InputGameEvent(this.ownerId);
}

class InputMessageEvent extends InputGameEvent {
  final String message;

  InputMessageEvent(this.message, int ownerId) : super(ownerId);
}

class InputWordEvent extends InputGameEvent {
  final String word;

  InputWordEvent(this.word, int ownerId) : super(ownerId);
}
