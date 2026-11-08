import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data/picture_source.dart';

/// Contains authorization data
abstract class ClientAccountInfo {
  /// User name
  String get name;

  /// Profile picture URI
  PictureSource get picture;

  /// `True` is the user wants receive messages from the other users.
  bool get canReceiveMessages;

  const ClientAccountInfo();
}

/// [ClientAccountInfo] for local users
class LocalAccountInfo extends ClientAccountInfo with Equatable {
  @override
  final PictureSource picture;

  const LocalAccountInfo({required this.name, required this.picture});

  @override
  final String name;

  @override
  bool get canReceiveMessages => false;

  @override
  List<Object> get props => [name, picture];
}
