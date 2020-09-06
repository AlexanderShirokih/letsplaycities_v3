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
class CityInfo extends GameItem {
  final String city;
  final CityStatus status;
  final int countryCode;

  CityInfo({
    User owner,
    this.city,
    this.status = CityStatus.WAITING,
    this.countryCode = 0,
  }) : super(owner);

  @override
  int get hashCode => city.hashCode;

  @override
  bool operator ==(Object o) =>
      o is CityInfo &&
      city == o.city &&
      status == o.status &&
      countryCode == o.countryCode;

  @override
  bool hasTheSameBaseData(GameItem o) =>
      o is CityInfo && this.owner == o.owner && this.city == o.city;
}

/// Info containing data about [message].
class MessageInfo extends GameItem {
  final String message;

  MessageInfo({this.message, User owner}) : super(owner);

  @override
  int get hashCode => message.hashCode;

  @override
  bool operator ==(Object o) => o is MessageInfo && message == o.message;

  @override
  bool hasTheSameBaseData(GameItem o) =>
      o is MessageInfo && this.owner == o.owner && this.message == o.message;
}
