import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/base/dictionary.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/scoring.dart';
import 'package:lets_play_cities/screens/common/dialogs.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/settings/stats/stats_screen.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) => withLocalization(
        context,
        (l10n) => Scaffold(
          appBar: AppBar(
            title: Text(l10n.settings['settings']),
          ),
          body: _SettingsItemsList(
              l10n.settings, context.repository<GamePreferences>()),
        ),
      );
}

class _SettingsItemsList extends StatefulWidget {
  final Map<String, dynamic> _settings;
  final List<String> _titles;
  final List<String> _onOff;
  final GamePreferences _prefs;

  _SettingsItemsList(this._settings, this._prefs)
      : _titles =
            (_settings['settings_item_titles'] as List<dynamic>).cast<String>(),
        _onOff = (_settings['on_off'] as List<dynamic>).cast<String>();

  // TODO: Implement another screens: ThemeSelectorScreen, BlacklistScreen
  @override
  _SettingsItemsListState createState() => _SettingsItemsListState(
        [
          _NavigationItem(_titles[0], 'Unimplemented', null),
          _SingleChoiceItem(
            _titles[1],
            (_settings['difficulty'] as List<dynamic>).cast<String>(),
            _prefs.wordsDifficulty.index,
            onSet: (i) => _prefs.wordsDifficulty = Difficulty.values[i],
          ),
          _SingleChoiceItem(
            _titles[2],
            (_settings['scoring_type'] as List<dynamic>).cast<String>(),
            _prefs.scoringType.index,
            onSet: (i) => _prefs.scoringType = ScoringType.values[i],
          ),
          _SingleChoiceItem(
            _titles[3],
            (_settings['move_timer'] as List<dynamic>).cast<String>(),
            _timerValueToIndex(_prefs.timeLimit),
            useRadio: true,
            onSet: (i) => _prefs.timeLimit = _indexToTimeValue(i),
          ),
          _ToggleItem(_titles[4], _onOff, _prefs.correctionEnabled,
              onSet: (f) => _prefs.correctionEnabled = f),
          _ToggleItem(_titles[5], _onOff, _prefs.soundEnabled,
              onSet: (f) => _prefs.soundEnabled = f),
          _ToggleItem(_titles[6], _onOff, _prefs.onlineChatEnabled,
              onSet: (f) => _prefs.onlineChatEnabled = f),
          _NavigationItem(
              _titles[7], _settings['statistic_sub'], () => StatisticsScreen()),
          _NavigationItem(_titles[8], _settings['blacklist_sub'], null),
          _SingleChoiceItem(
            _titles[9],
            (_settings['dict_upd_period'] as List<dynamic>).cast<String>(),
            _prefs.dictionaryUpdatePeriod.index,
            useRadio: true,
            onSet: (i) => _prefs.dictionaryUpdatePeriod =
                DictionaryUpdatePeriod.values[i],
          ),
        ],
      );

  static final _acceptedValues = [0, 1, 2, 5, 10, 15];

  int _timerValueToIndex(int timerValueInSec) =>
      _acceptedValues.indexWhere((e) => e >= timerValueInSec ~/ 60);

  int _indexToTimeValue(int index) => _acceptedValues[index] * 60;
}

class _SettingsItemsListState extends State<_SettingsItemsList> {
  final List<_SettingsItem> _items;

  _SettingsItemsListState(this._items);

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
                      value: item.isChecked,
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

  bool get isChecked;

  String get subtitle;

  Future<void> onClicked(BuildContext context);
}

typedef ScreenSelector = Widget Function();

// When clicked navigates to specifies destination
class _NavigationItem extends _SettingsItem {
  final String _subtitle;
  final ScreenSelector _selector;

  _NavigationItem(String title, this._subtitle, this._selector) : super(title);

  @override
  Future<void> onClicked(BuildContext context) {
    if (_selector != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => _selector()));
    }
    return Future.value();
  }

  @override
  bool get isChecked => null;

  @override
  String get subtitle => _subtitle;
}

class _ToggleItem extends _SettingsItem {
  final List<String> _stateNames;
  final Function(bool) onSet;

  bool _isChecked;

  _ToggleItem(String title, this._stateNames, bool initialState,
      {@required this.onSet})
      : _isChecked = initialState,
        assert(onSet != null),
        super(title);

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

  _SingleChoiceItem(String title, this._choiceItems, this._currentChoice,
      {bool useRadio, @required this.onSet})
      : _useRadio = useRadio ?? false,
        assert(onSet != null),
        super(title);

  @override
  bool get isChecked => _useRadio ? _currentChoice != 0 : null;

  @override
  Future<void> onClicked(BuildContext context) =>
      showSingleChoiceDialog(context, title, _choiceItems, _currentChoice)
          .then((value) {
        if (value != null) {
          _currentChoice = value;
          onSet(value);
        }
      });

  @override
  String get subtitle => _choiceItems[_currentChoice];
}
