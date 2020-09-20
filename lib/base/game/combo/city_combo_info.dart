/// Data class for collect info about finished move parameters
class CityComboInfo {
  static const _QUICK_MOVE_TIME = 5000;
  static const _SHORT_WORD_SIZE = 4;
  static const _LONG_WORD_SIZE = 8;

  final bool isQuick;
  final bool isShort;
  final bool isLong;
  final int countryCode;

  CityComboInfo._(this.isQuick, this.isShort, this.isLong, this.countryCode);

  factory CityComboInfo.fromMoveParams(
          int deltaTimeInMs, String word, int countryCode) =>
      CityComboInfo._(
          deltaTimeInMs <= _QUICK_MOVE_TIME,
          word.length <= _SHORT_WORD_SIZE,
          word.length >= _LONG_WORD_SIZE,
          countryCode);
}
