import '../users.dart';

/// Wrapper for the city name and its owner
class City {
  final String city;
  final User owner;

  City(this.city, this.owner);
}

enum CityStatus { OK, WAITING, ERROR }

/// Represents user position on the screen
enum Position { LEFT, RIGHT, UNKNOWN }
