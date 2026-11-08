/// Data class for collect info about finished move parameters
class CityComboInfo {
  static const _quickMoveTime = 5000;
  static const _shortWordSize = 4;
  static const _longWordSize = 8;

  final bool isQuick;
  final bool isShort;
  final bool isLong;
  final int countryCode;

  CityComboInfo._(this.isQuick, this.isShort, this.isLong, this.countryCode);

  factory CityComboInfo.fromMoveParams(
    int deltaTimeInMs,
    String word,
    int countryCode,
  ) => CityComboInfo._(
    deltaTimeInMs <= _quickMoveTime,
    word.length <= _shortWordSize,
    word.length >= _longWordSize,
    countryCode,
  );
}
