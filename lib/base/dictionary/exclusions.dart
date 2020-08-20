/// Describes interface for city exclusions.
class ExclusionsService {
  /// Checks [city] for any exclusions except of alternative names.
  /// @return Description of exclusion for [city] or empty string if [city] has no exclusions.
  String checkForExclusion(String city) => "";

  /// Checks for any kind of exclusions.
  /// @return true` if [input] has no exclusions, `false` otherwise.
  bool hasNoExclusions(String input) => true;

  /// Returns alternative name for given [city] or `null` if it found.
  /// @param city city for checking its alternative name
  /// @return alternative name of this city or empty string if there are no names found.
  String getAlternativeName(String city) => "";
}
