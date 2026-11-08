/// Describes city properties, such as:
/// Country code - country flag index
/// Difficulty level - difficulty of the city name for average user (0-3)
/// Usage flag - when raised - city wasn't used in the game
class CityProperties {
  static const _difficultyBitsOffset = 16;

  static const _countryCodeMask = 0xFFFF;
  static const _difficultyMask = 0x030000;
  static const _usageFlagMask = 0x1000000;

  // 0-15 bits - country code bits.
  // 16-23 bits - difficulty index bits
  // 24 bit - usage flag
  int _dataBits;

  /// Creates new instance from difficulty level and country code
  CityProperties({required int difficulty, required int countryCode})
    : assert(
        difficulty >= 0 && difficulty < 3,
        'Invalid difficulty value=$difficulty',
      ),
      assert(
        countryCode >= 0 && countryCode.bitLength < 16,
        'Invalid country code value=$countryCode',
      ),
      _dataBits =
          countryCode & _countryCodeMask |
          (difficulty << _difficultyBitsOffset) & _difficultyMask;

  /// Bitmask layout: [difficulty(u8)][countryCode(u16)] <- 0
  /// Other bits will be clears using logic AND mask
  CityProperties.fromBitmask(int bitmask) : _dataBits = bitmask & 0xFFFFFF;

  /// Raises usage flag
  void markUsed() => _dataBits |= _usageFlagMask;

  /// Clears usage flag
  void reset() => _dataBits &= ~(_usageFlagMask);

  /// Returns `true` when usage flag is raised
  bool get used => _dataBits & _usageFlagMask != 0;

  /// Returns difficulty level index (0-2).
  /// Where: 0- Easy, 1- Medium, 2-Hard
  int get difficulty => (_dataBits & _difficultyMask) >> _difficultyBitsOffset;

  /// Returns the country code index
  int get countryCode => _dataBits & _countryCodeMask;
}
