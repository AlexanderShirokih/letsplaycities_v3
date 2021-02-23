/// Service used to resolve overrides of country-city pair in some locales
abstract class CountryCodeOverrides {
  /// Finds override for given [word].
  /// Returns overridden country code or `null` if there is no overrides for
  /// [word].
  int? findOverride(String word);
}
