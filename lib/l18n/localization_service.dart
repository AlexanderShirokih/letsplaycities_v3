import 'localizations_keys.dart';

/// Represents interface for loading localized strings
abstract class LocalizationService {
  Map<ErrorCode, String> get exclusionDescriptions;

  String get yes;

  String get no;

  /// GameScreen localizations
  Map<String, dynamic> get game;
}
