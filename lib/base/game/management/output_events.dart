import 'package:meta/meta.dart';

@sealed
abstract class OutputEvent {}

class OutputMessageEvent extends OutputEvent {
  final String message;

  OutputMessageEvent(this.message);
}

class OutputWordEvent extends OutputEvent {
  final String word;

  OutputWordEvent(this.word);
}
