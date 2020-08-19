import 'package:lets_play_cities/base/data/city_data.dart';

/// Represents model of the game item (city or message).
class GameItem {
  final Position position;

  GameItem(this.position);
}

/// Info containing data about [city], [position] on the screen,
/// [countryCode] of cities country in database and current [status]
/// of the city (waiting for confirmation, error, accepted).
class CityInfo extends GameItem {
  final String city;
  final CityStatus status;
  final int countryCode;

  CityInfo(
      {this.city,
      Position position,
      this.status = CityStatus.WAITING,
      this.countryCode = 0})
      : super(position);

  @override
  int get hashCode => city.hashCode;

  @override
  bool operator ==(Object o) =>
      o is CityInfo &&
      city == o.city &&
      status == o.status &&
      countryCode == o.countryCode;
}

/// Info containing data about [message].
class MessageInfo extends GameItem {
  final String message;

  MessageInfo({this.message, Position position}) : super(position);

  @override
  int get hashCode => message.hashCode;

  @override
  bool operator ==(Object o) => o is MessageInfo && message == o.message;
}
