import 'package:lets_play_cities/base/users.dart';
import 'package:meta/meta.dart';

@sealed
abstract class OutputEvent {}

class OutputMessageEvent extends OutputEvent {
  final User owner;
  final String message;

  OutputMessageEvent(this.message, this.owner);
}

class OutputWordEvent extends OutputEvent {
  final User owner;
  final String word;

  OutputWordEvent(this.word, this.owner);
}
