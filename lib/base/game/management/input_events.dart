import 'package:meta/meta.dart';

@sealed
abstract class InputEvent {}

class InputMessageEvent extends InputEvent {
  final String message;

  InputMessageEvent(this.message);
}

class InputWordEvent extends InputEvent {
  final String word;

  InputWordEvent(this.word);
}
