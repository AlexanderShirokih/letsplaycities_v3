import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                  child: MaterialApp(
                    theme: ThemeData(
                      primarySwatch: Colors.orange,
                      visualDensity: VisualDensity.adaptivePlatformDensity,
                    ),
                    home: Scaffold(body: MainScreen()),
                  ),
                )
              : Center(
                  child: (snap.hasError
                      ? Text("Fatal error: cannot load localizations!",
                          textDirection: TextDirection.ltr)
                      : CircularProgressIndicator()));
        },
        future: initWithMigrations(),
      );

  Future<_InitialData> initWithMigrations() => SharedPreferencesMigration()
      .migrateSharedPreferencesIfNeeded()
      .then((_) => getRootDependencies());

  Future<_InitialData> getRootDependencies() async {
    return _InitialData(
      localizations: await LocalizationsFactory().createDefaultLocalizations(),
      preferences:
          SharedPreferencesGamePrefs(await SharedPreferences.getInstance()),
    );
  }
}
