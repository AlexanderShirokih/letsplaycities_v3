import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';
import 'package:lets_play_cities/screens/settings/stats/stats_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.settings.settings)),
      body: _SettingsItemsList(t, context.watch<GamePreferences>()),
    );
  }
}

class _SettingsItemsList extends StatefulWidget {
  final Translations _t;
  final GamePreferences _prefs;

  const _SettingsItemsList(this._t, this._prefs);

  @override
  State<_SettingsItemsList> createState() => _SettingsItemsListState();

  /// Creates the items from the current preferences. Items hold the values
  /// the user changes, so the [State] creates them once and keeps them.
  List<_SettingsItem> _createItems() {
    final titles = _t.settings.settingsItemTitles;
    final onOff = [_t.settings.onOff.off, _t.settings.onOff.on];
    return [
      _SingleChoiceItem(
        titles.difficulty,
        [for (final value in Difficulty.values) value.label(_t)],
        _prefs.wordsDifficulty.index,
        onSet: (i) => _prefs.wordsDifficulty = Difficulty.values[i],
      ),
      _SingleChoiceItem(
        titles.scoring,
        [for (final value in ScoringType.values) value.label(_t)],
        _prefs.scoringType.index,
        onSet: (i) => _prefs.scoringType = ScoringType.values[i],
      ),
      _SingleChoiceItem(
        titles.moveTimer,
        [
          for (final minutes in _acceptedValues)
            minutes == 0
                ? _t.settings.moveTimer.off
                : _t.settings.moveTimer.minutes(n: minutes),
        ],
        _timerValueToIndex(_prefs.timeLimit),
        useRadio: true,
        onSet: (i) => _prefs.timeLimit = _indexToTimeValue(i),
      ),
      _ToggleItem(
        titles.correction,
        onOff,
        _prefs.correctionEnabled,
        onSet: (f) => _prefs.correctionEnabled = f,
      ),
      _ToggleItem(
        titles.sound,
        onOff,
        _prefs.soundEnabled,
        onSet: (f) => _prefs.soundEnabled = f,
      ),
      _ToggleItem(
        titles.onlineChat,
        onOff,
        _prefs.onlineChatEnabled,
        onSet: (f) => _prefs.onlineChatEnabled = f,
      ),
      _NavigationItem(
        titles.statistics,
        () => _t.settings.statisticSub,
        () => StatisticsScreen(),
      ),
      _SingleChoiceItem(
        titles.dictUpdates,
        [for (final value in DictionaryUpdatePeriod.values) value.label(_t)],
        _prefs.dictionaryUpdatePeriod.index,
        useRadio: true,
        onSet: (i) =>
            _prefs.dictionaryUpdatePeriod = DictionaryUpdatePeriod.values[i],
      ),
    ];
  }

  static final _acceptedValues = [0, 1, 2, 5, 10, 15];

  int _timerValueToIndex(int timerValueInSec) =>
      _acceptedValues.indexWhere((e) => e >= timerValueInSec ~/ 60);

  int _indexToTimeValue(int index) => _acceptedValues[index] * 60;
}

class _SettingsItemsListState extends State<_SettingsItemsList> {
  late final List<_SettingsItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget._createItems();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _items
          .map(
            (item) => ListTile(
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: item.isChecked == null
                  ? null
                  : Switch(
                      value: item.isChecked!,
                      onChanged: (_) => _onItemClicked(item),
                    ),
              onTap: () => _onItemClicked(item),
            ),
          )
          .toList(growable: false),
    );
  }

  void _onItemClicked(_SettingsItem item) =>
      item.onClicked(context).then((_) => setState(() {}));
}

// Describes base settings item properties. Inherited classes should define the click behaviour
abstract class _SettingsItem {
  final String title;

  _SettingsItem(this.title);

  bool? get isChecked;

  String get subtitle;

  Future<void> onClicked(BuildContext context);
}

typedef ScreenSelector = Widget Function();

// When item is clicked then navigates to the specified destination.
// The subtitle is read on every build, because the destination may change
// what it shows (e.g. the current theme name).
class _NavigationItem extends _SettingsItem {
  final String Function() _subtitle;
  final ScreenSelector _selector;

  _NavigationItem(super.title, this._subtitle, this._selector);

  @override
  Future<void> onClicked(BuildContext context) {
    return Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => _selector()));
  }

  @override
  bool? get isChecked => null;

  @override
  String get subtitle => _subtitle();
}

class _ToggleItem extends _SettingsItem {
  final List<String> _stateNames;
  final Function(bool) onSet;

  bool _isChecked;

  _ToggleItem(
    super.title,
    this._stateNames,
    bool initialState, {
    required this.onSet,
  }) : _isChecked = initialState;

  @override
  bool get isChecked => _isChecked;

  @override
  Future<void> onClicked(BuildContext context) async {
    _isChecked = !_isChecked;
    onSet(_isChecked);
  }

  @override
  String get subtitle => _isChecked ? _stateNames[1] : _stateNames[0];
}

class _SingleChoiceItem extends _SettingsItem {
  final List<String> _choiceItems;

  final bool _useRadio;
  int _currentChoice;
  Function(int) onSet;

  _SingleChoiceItem(
    super.title,
    this._choiceItems,
    this._currentChoice, {
    bool? useRadio,
    required this.onSet,
  }) : _useRadio = useRadio ?? false;

  @override
  bool? get isChecked => _useRadio ? _currentChoice != 0 : null;

  @override
  Future<void> onClicked(BuildContext context) =>
      showSingleChoiceDialog(context, title, _choiceItems, _currentChoice).then(
        (value) {
          if (value != null) {
            _currentChoice = value;
            onSet(value);
          }
        },
      );

  @override
  String get subtitle => _choiceItems[_currentChoice];
}
