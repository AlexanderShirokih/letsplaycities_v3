// Describes combo types
enum ComboType {
  quickTime,
  shortWord,
  longWord,
  sameCountry,
  differentCountries,
}

extension ComboTypeMinSize on ComboType {
  int get minSize {
    switch (this) {
      case ComboType.quickTime:
      case ComboType.shortWord:
      case ComboType.longWord:
        return 3;
      case ComboType.sameCountry:
        return 7;
      case ComboType.differentCountries:
        return 6;
    }
  }
}
