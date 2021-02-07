import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_stream_listener/flutter_stream_listener.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as theme;
import 'package:lets_play_cities/base/themes/theme_manager.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/platform/shared_prefs_migration.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/screens/main/main_screen.dart';
import 'package:lets_play_cities/screens/online/game_request_view.dart';

// ignore: import_of_legacy_library_into_null_safe

/// Application root class
class LetsPlayCitiesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _initWithMigrations(),
        builder: (context, snap) {
          final getIt = GetIt.instance;
          return snap.hasData
              ? MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider<GamePreferences>(
                      create: (_) => getIt.get<GamePreferences>(),
                    ),
                    RepositoryProvider<LocalizationService>(
                      create: (_) => getIt.get<LocalizationService>(),
                    ),
                  ],
                  child: StreamBuilder<theme.Theme>(
                    stream: getIt.get<ThemeManager>().currentTheme,
                    initialData: getIt.get<ThemeManager>().fallback,
                    builder: (_, snap) {
                      final currentTheme = snap.requireData;
                      final dark = getIt.get<ThemeManager>().dark;
                      final brightness =
                          WidgetsBinding.instance!.window.platformBrightness;
                      final isSystemDark = brightness == Brightness.dark;
                      return snap.hasData
                          ? RepositoryProvider.value(
                              value: isSystemDark ? dark : currentTheme,
                              child: MaterialApp(
                                theme: ThemeData(
                                  primarySwatch: currentTheme.primaryColor,
                                  accentColor: currentTheme.primaryColor,
                                  brightness: currentTheme.isDark
                                      ? Brightness.dark
                                      : Brightness.light,
                                  visualDensity:
                                      VisualDensity.adaptivePlatformDensity,
                                ),
                                darkTheme: ThemeData(
                                  primarySwatch: dark.primaryColor,
                                  accentColor: dark.primaryColor,
                                  brightness: Brightness.dark,
                                ),
                                home: _buildAppHome(),
                              ),
                            )
                          : _showWaitForDataWidget(
                              snap, 'Fatal error: cannot load theme!');
                    },
                  ),
                )
              : _showWaitForDataWidget(
                  snap, 'Fatal error: cannot load root dependencies!');
        },
      );

  Widget _buildAppHome() => Scaffold(
        body: Builder(
          builder: (context) => StreamListener<GameRequest>(
            stream: GetIt.instance
                .get<CloudMessagingService>()
                .messages
                .where((event) => event is GameRequest)
                .cast<GameRequest>(),
            onData: (request) {
              showModalBottomSheet<void>(
                context: context,
                builder: (ctx) => GameRequestView(request: request),
              );
            },
            child: SafeArea(child: MainScreen()),
          ),
        ),
      );

  Widget _showWaitForDataWidget(AsyncSnapshot snap, String errText) {
    return Center(
      child: (snap.hasError
          ? Text(errText, textDirection: TextDirection.ltr)
          : CircularProgressIndicator()),
    );
  }

  Future<bool> _initWithMigrations() async {
    await SharedPreferencesMigration().migrateSharedPreferencesIfNeeded();

    await GetIt.instance.allReady();

    return true;
  }
}
