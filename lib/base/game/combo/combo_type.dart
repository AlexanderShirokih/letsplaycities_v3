// Describes combo types
enum ComboType {
  QUICK_TIME,
  SHORT_WORD,
  LONG_WORD,
  SAME_COUNTRY,
  DIFFERENT_COUNTRIES
}

extension ComboTypeMinSize on ComboType {
  int get minSize {
    switch (this) {
      case ComboType.QUICK_TIME:
      case ComboType.SHORT_WORD:
      case ComboType.LONG_WORD:
        return 3;
      case ComboType.SAME_COUNTRY:
        return 7;
      case ComboType.DIFFERENT_COUNTRIES:
        return 6;
    }
    throw ("Bad state!");
  }
}
