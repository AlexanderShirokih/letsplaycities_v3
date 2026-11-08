import 'package:lets_play_cities/base/dictionary/dictionary_update_period.dart';

/// Move timer values in seconds shown by the settings, 0 is no timer
const timerOptions = [30, 60, 120, 0];

/// The option that equals [seconds], or `null` for a stored value outside
/// the list
int? timerOptionFor(int seconds) =>
    timerOptions.contains(seconds) ? seconds : null;

/// The dictionary updates switch is on for every period but `never`
bool dictionaryUpdatesOn(DictionaryUpdatePeriod p) =>
    p != DictionaryUpdatePeriod.never;

DictionaryUpdatePeriod dictionaryPeriodFor(bool on) =>
    on ? DictionaryUpdatePeriod.daily : DictionaryUpdatePeriod.never;
