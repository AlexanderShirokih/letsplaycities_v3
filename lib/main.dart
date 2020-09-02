import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/l18n/localizations_factory.dart';
import 'package:lets_play_cities/screens/main/main_screen.dart';

void main() => runApp(LetsPlayCitiesApp());

/// Application root class
class LetsPlayCitiesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder(
        builder: (context, snap) {
          return snap.hasData
              ? MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider<GamePreferences>(
                      create: (_) => GamePreferences(),
                    ),
                    RepositoryProvider<LocalizationService>(
                      create: (_) => snap.data,
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
        future: LocalizationsFactory().createDefaultLocalizations(),
      );
}
