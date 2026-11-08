/// Describes dictionary update period constants
enum DictionaryUpdatePeriod { never, threeHours, daily }

extension DictionaryUpdatePeriodExt on DictionaryUpdatePeriod {
  Duration asDuration() {
    switch (this) {
      case DictionaryUpdatePeriod.never:
        return Duration.zero;
      case DictionaryUpdatePeriod.threeHours:
        return const Duration(hours: 3);
      case DictionaryUpdatePeriod.daily:
        return const Duration(days: 1);
    }
  }
}
