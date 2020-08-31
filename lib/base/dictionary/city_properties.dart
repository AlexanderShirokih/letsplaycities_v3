import 'package:meta/meta.dart';

/// Describes city properties, such as:
/// Country code - country flag index
/// Difficulty level - difficulty of the city name for average user (0-3)
/// Usage flag - when raised - city wasn't used in the game
class CityProperties {
  static const _DIFFICULTY_BITS_OFFSET = 8;

  static const _COUNTY_CODE_MASK = 0xFF;
  static const _DIFFICULTY_MASK = 0x03 << _DIFFICULTY_BITS_OFFSET;
  static const _USAGE_FLAG_MASK = 0x4000;

  // 0-7 bits - country code bits.
  // 8-9 bits - difficulty index bits
  // 10 bit - usage flag
  int _dataBits;

  /// Creates new instance from difficulty level and country code
  CityProperties({@required int difficulty, @required int countryCode})
      : assert(difficulty != null && countryCode != null),
        assert(difficulty >= 0 && difficulty < 3),
        assert(countryCode >= 0 && countryCode <= 255),
        _dataBits = countryCode & _COUNTY_CODE_MASK |
            (difficulty << _DIFFICULTY_BITS_OFFSET) & _DIFFICULTY_MASK;

  CityProperties.fromBitmask(int bitmask) : _dataBits = bitmask;

  /// Raises usage flag
  void markUsed() => _dataBits |= _USAGE_FLAG_MASK;

  /// Clears usage flag
  void reset() => _dataBits &= ~(_USAGE_FLAG_MASK);

  /// Returns `true` when usage flag is raised
  bool get used => _dataBits & _USAGE_FLAG_MASK != 0;

  /// Returns difficulty level index (0-2).
  /// Where: 0- Easy, 1- Medium, 2-Hard
  int get difficulty =>
      (_dataBits & _DIFFICULTY_MASK) >> _DIFFICULTY_BITS_OFFSET;

  /// Returns the country code index
  int get countryCode => _dataBits & _COUNTY_CODE_MASK;
}
