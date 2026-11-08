import 'package:clock/clock.dart';
import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/users.dart';

/// What happened in one game, for the results screen and local stats.
class GameSummary extends Equatable {
  /// Cities accepted from every user
  final int citiesCount;

  /// Time from the start of the first move to the end of the game
  final Duration duration;

  /// The longest city named by a [Player], `null` if they named none.
  /// The country code is 0 when it is unknown.
  final ({String city, int countryCode})? longestCity;

  /// The highest level each combo type reached in [Player] moves, as the
  /// combo stats store it
  final Map<ComboType, int> bestCombos;

  /// Known country codes of the cities named by [Player]s
  final Set<int> playerCountries;

  const GameSummary({
    required this.citiesCount,
    required this.duration,
    required this.longestCity,
    required this.bestCombos,
    required this.playerCountries,
  });

  static const empty = GameSummary(
    citiesCount: 0,
    duration: Duration.zero,
    longestCity: null,
    bestCombos: {},
    playerCountries: {},
  );

  @override
  List<Object?> get props => [
    citiesCount,
    duration,
    longestCity,
    bestCombos,
    playerCountries,
  ];
}

/// Collects [GameSummary] while the game goes on.
class GameSummaryBuilder {
  final Clock _clock;

  DateTime? _startTime;
  int _citiesCount = 0;
  ({String city, int countryCode})? _longestCity;
  final _bestCombos = <ComboType, int>{};
  final _playerCountries = <int>{};

  GameSummaryBuilder(this._clock);

  /// Marks the start of the first move; later calls change nothing.
  void start() => _startTime ??= _clock.now();

  /// Counts [word] accepted from [owner]; a [countryCode] of 0 is unknown.
  void onAccepted(User owner, String word, int countryCode) {
    _citiesCount++;

    if (owner is! Player) return;

    // On equal length the first city stays.
    if (word.length > (_longestCity?.city.length ?? 0)) {
      _longestCity = (city: word, countryCode: countryCode);
    }

    if (countryCode > 0) _playerCountries.add(countryCode);
  }

  /// Takes the combo levels [active] after a move of [owner].
  void onCombos(User owner, Map<ComboType, int> active) {
    if (owner is! Player) return;

    for (final MapEntry(key: type, value: level) in active.entries) {
      if (level > (_bestCombos[type] ?? 0)) _bestCombos[type] = level;
    }
  }

  GameSummary build() {
    final startTime = _startTime;

    return GameSummary(
      citiesCount: _citiesCount,
      duration: startTime == null
          ? Duration.zero
          : _clock.now().difference(startTime),
      longestCity: _longestCity,
      bestCombos: Map.unmodifiable(_bestCombos),
      playerCountries: Set.unmodifiable(_playerCountries),
    );
  }
}
