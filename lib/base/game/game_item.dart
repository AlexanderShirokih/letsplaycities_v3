import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/users.dart';

/// Represents model of the game item (city or message).
abstract class GameItem {
  final User owner;

  GameItem(this.owner);

  /// Returns true if base params of the game item are the same with [other]
  bool hasTheSameBaseData(GameItem other);
}

/// Info containing data about [city], [position] on the screen,
/// [countryCode] of cities country in database and current [status]
/// of the city (waiting for confirmation, error, accepted).
class CityInfo extends GameItem with EquatableMixin {
  final String city;
  final CityStatus status;
  final int countryCode;

  CityInfo({
    required User owner,
    required this.city,
    this.status = CityStatus.WAITING,
    this.countryCode = 0,
  }) : super(owner);

  @override
  int get hashCode => city.hashCode;

  @override
  bool hasTheSameBaseData(GameItem o) =>
      o is CityInfo && owner == o.owner && city == o.city;

  @override
  List<Object?> get props => [city, status, countryCode];
}

/// Info containing data about [message].
class MessageInfo extends GameItem with EquatableMixin {
  final String message;

  MessageInfo({
    required this.message,
    required User owner,
  }) : super(owner);

  @override
  int get hashCode => message.hashCode;

  @override
  List<Object?> get props => [message];

  @override
  bool hasTheSameBaseData(GameItem o) =>
      o is MessageInfo && owner == o.owner && message == o.message;
}
