import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/game/player/user.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as themes;
import 'package:lets_play_cities/base/themes/theme_manager.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';

/// Screen used to switch current application theme
class ThemeManagerScreen extends StatelessWidget {
  final ThemeManager _themeManager;

  /// Country codes of the sample cities (Берлин, Нью-Йорк, Казань), in the
  /// order of `t.themes.sampleCities`.
  static const _sampleCountryCodes = [118, 44, 51];

  ThemeManagerScreen({super.key})
    : _themeManager = GetIt.instance.get<ThemeManager>();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Scaffold(
      appBar: AppBar(title: Text(t.themes.title)),
      body: SafeArea(
        child: FutureBuilder<themes.Theme>(
          initialData: _themeManager.fallback,
          future: _themeManager.currentTheme.first,
          builder: (_, snap) => ListView(
            children: _themeManager.availableThemes
                .map((theme) => _buildThemeItem(t, theme, theme == snap.data))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeItem(Translations t, themes.Theme theme, bool isActive) {
    final even = _StubUser(true);
    final odd = _StubUser(false);
    final samples = t.themes.sampleCities;

    return Theme(
      data: ThemeData.from(
        colorScheme: ColorScheme.fromSwatch(
          accentColor: theme.accentColor,
          primarySwatch: theme.primaryColor,
          brightness: theme.isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      child: RepositoryProvider<themes.Theme>.value(
        value: theme,
        child: GestureDetector(
          onTap: () => _themeManager.setCurrent(theme),
          child: Card(
            elevation: 6.0,
            margin: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Builder(builder: (context) => createBackground(context)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      color: theme.primaryColor,
                      height: 42.0,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 12.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Text(
                              t.themes.themeNames[theme.name]!,
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
                          if (isActive) Icon(Icons.done),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(samples.length, (index) {
                        return GameItemListTile(
                          CityInfo(
                            owner: index % 2 == 0 ? even : odd,
                            status: CityStatus.ok,
                            city: samples[index],
                            countryCode: _sampleCountryCodes[index],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StubUser extends User {
  _StubUser(bool alignRight)
    : super(
        isTrusted: true,
        comboSystem: ComboSystem(canUseQuickTime: false),
        accountInfo: _StubClientAccountInfo(),
      ) {
    position = alignRight ? Position.right : Position.left;
  }

  @override
  Future<String> onCreateWord(String firstChar) => Future.error('Stub called!');
}

class _StubClientAccountInfo extends ClientAccountInfo {
  @override
  bool get canReceiveMessages => false;

  @override
  String get name => 'Stub!';

  @override
  PictureSource get picture => const PlaceholderPictureSource();
}
