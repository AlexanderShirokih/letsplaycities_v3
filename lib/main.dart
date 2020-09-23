import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/themes/theme.dart' as theme;
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/l18n/localizations_factory.dart';
import 'package:lets_play_cities/migration/shared_prefs_migration.dart';
import 'package:lets_play_cities/screens/main/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(LetsPlayCitiesApp());

class _InitialData {
  final LocalizationService localizations;
  final GamePreferences preferences;

  const _InitialData({this.localizations, this.preferences})
      : assert(localizations != null),
        assert(preferences != null);
}

/// Application root class
class LetsPlayCitiesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<_InitialData>(
        builder: (context, snap) {
          return snap.hasData
              ? MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider<GamePreferences>(
                      create: (_) => snap.data.preferences,
                    ),
                    RepositoryProvider<LocalizationService>(
                      create: (_) => snap.data.localizations,
                    ),
                  ],
                  child: StreamBuilder<theme.Theme>(
                    stream: Stream.value(
                      theme.Theme(
                        backgroundImage: "assets/images/backgrounds/bg_geo.png",
                      ),
                    ),
                    builder: (_, snap) => snap.hasData
                        ? RepositoryProvider.value(
                            value: snap.requireData,
                            child: MaterialApp(
                              theme: ThemeData(
                                primarySwatch: Colors.orange,
                                accentColor: Colors.blue[900],
                                visualDensity:
                                    VisualDensity.adaptivePlatformDensity,
                              ),
                              home: Scaffold(body: MainScreen()),
                            ),
                          )
                        : _showWaitForDataWidget(
                            snap, "Fatal error: cannot load theme!"),
                  ),
                )
              : _showWaitForDataWidget(
                  snap, "Fatal error: cannot load localizations!");
        },
        future: _initWithMigrations(),
      );

  Widget _showWaitForDataWidget(AsyncSnapshot snap, String errText) => Center(
      child: (snap.hasError
          ? Text(errText, textDirection: TextDirection.ltr)
          : CircularProgressIndicator()));

  Future<_InitialData> _initWithMigrations() => SharedPreferencesMigration()
      .migrateSharedPreferencesIfNeeded()
      .then((_) => _getRootDependencies());

  Future<_InitialData> _getRootDependencies() async {
    return _InitialData(
      localizations: await LocalizationsFactory().createDefaultLocalizations(),
      preferences:
          SharedPreferencesGamePrefs(await SharedPreferences.getInstance()),
    );
  }
}
