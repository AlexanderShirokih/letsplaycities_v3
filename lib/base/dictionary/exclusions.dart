/// Describes interface for city exclusions.
abstract class ExclusionsService {
  /// Checks [city] for any exclusions except of alternative names.
  /// Returns description of exclusion for [city] or empty string if [city] has no exclusions.
  String checkForExclusion(String city);

  /// Checks for any kind of exclusions.
  /// Returns rue` if [input] has no exclusions, `false` otherwise.
  bool hasNoExclusions(String input);

  /// Returns alternative name for given [city] or `null` if it found.
  /// Returns alternative name of this city or empty string if there are no names found.
  String getAlternativeName(String city);
}
