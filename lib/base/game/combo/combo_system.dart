import 'dart:async';
import 'dart:math';

import 'package:lets_play_cities/base/game/combo.dart';

/// Manages user combos
class ComboSystem {
  static const _kMaxSingleScore = 3.0;

  final bool canUseQuickTime;

  final Map<ComboType, int> _activeCombos = {};

  final List<CityComboInfo> _infoList = [];

  final _controller = StreamController<Map<ComboType, int>>();

  ComboSystem({required this.canUseQuickTime});

  /// Returns stream emitting events every time when combos changed
  Stream<Map<ComboType, int>> get eventStream => _controller.stream;

  /// Returns immutable map of current active combos
  Map<ComboType, int> get activeCombos => Map.unmodifiable(_activeCombos);

  /// Returns current score multiplier
  double get multiplier => _activeCombos.isEmpty
      ? 1.0
      : max(
          _activeCombos.values
              .map((combo) => _getScore(combo))
              .reduce((value, element) => value + element),
          1.0,
        );

  double _getScore(int s) => min((s + 1) * 0.5 + 0.5, _kMaxSingleScore);

  /// Adds [CityComboInfo] to list and updates combos
  void addCity(CityComboInfo cityComboInfo) {
    _infoList.add(cityComboInfo);
    _updateCombos();
  }

  void _updateCombos() {
    final usedCountries = <int>[];
    final lastCountryCode = _infoList.isEmpty ? 0 : _infoList.last.countryCode;

    final isAnyComboChanged = [
      _updateCombo(
          ComboType.QUICK_TIME, (info) => canUseQuickTime && info.isQuick),
      _updateCombo(ComboType.SHORT_WORD, (info) => info.isShort),
      _updateCombo(ComboType.LONG_WORD, (info) => info.isLong),
      _updateCombo(
          ComboType.SAME_COUNTRY,
          (info) =>
              info.countryCode > 0 && info.countryCode == lastCountryCode),
      _updateCombo(ComboType.DIFFERENT_COUNTRIES, (info) {
        final res = !usedCountries.contains(info.countryCode);
        usedCountries.add(info.countryCode);
        return res;
      })
    ].any((changed) => changed);

    if (isAnyComboChanged) {
      _controller.add(_activeCombos.map((type, level) =>
          MapEntry<ComboType, int>(type, _getScore(level).round())));
    }
  }

  bool _updateCombo(ComboType type, bool Function(CityComboInfo) predicate) {
    final comboLevel = _getCombo(type.minSize, predicate);

    if (comboLevel > 0) {
      _activeCombos[type] = comboLevel;
      return true;
    } else if (_activeCombos.remove(type) != null) {
      return true;
    }

    return false;
  }

  int _getCombo(
          int minComboSize, bool Function(CityComboInfo info) predicate) =>
      max(_infoList.reversed.takeWhile(predicate).length - minComboSize + 1, 0);

  /// Closes internal stream controller
  Future<void> close() => _controller.close();
}
