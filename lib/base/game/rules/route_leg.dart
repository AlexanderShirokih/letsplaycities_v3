import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/geo/geo_point.dart';
import 'package:lets_play_cities/base/users.dart';

/// One move of a route: a city that [owner] named or a skipped move.
class RouteLeg extends Equatable {
  /// Who made the move
  final User owner;

  /// The city, `null` if the move was skipped
  final String? city;

  /// Country of the [city], 0 when it is unknown
  final int countryCode;

  /// Where the [city] is, `null` for a skip or a city without coordinates
  final GeoPoint? point;

  /// Kilometers that the move brought to [owner]
  final int km;

  const RouteLeg({
    required this.owner,
    required this.city,
    required this.countryCode,
    required this.point,
    required this.km,
  });

  bool get skipped => city == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteLeg &&
          identical(owner, other.owner) &&
          city == other.city &&
          countryCode == other.countryCode &&
          km == other.km;

  @override
  int get hashCode =>
      Object.hash(identityHashCode(owner), city, countryCode, km);

  @override
  List<Object?> get props => [owner, city, countryCode, km];
}

/// The route of a match: every move made so far.
class RouteState extends Equatable {
  /// All moves in the order they were made
  final List<RouteLeg> legs;

  /// Kilometers of each user
  final Map<User, int> km;

  /// How many moves were made, skipped ones included
  final int movesDone;

  const RouteState({
    required this.legs,
    required this.km,
    required this.movesDone,
  });

  /// How many moves [user] has made, skipped ones included
  int movesOf(User user) =>
      legs.where((leg) => identical(leg.owner, user)).length;

  @override
  List<Object?> get props => [legs, movesDone];
}
