import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_stream_listener/flutter_stream_listener.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/platform/shared_prefs_migration.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/screens/main/main_screen.dart';
import 'package:lets_play_cities/screens/online/game_request_view.dart';
import 'package:lets_play_cities/themes/theme.dart' as theme;

// ignore: import_of_legacy_library_into_null_safe

/// Application root class
class LetsPlayCitiesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _initWithMigrations(),
        builder: (context, snap) {
          return snap.hasData
              ? MultiRepositoryProvider(
                  providers: [
                    RepositoryProvider<GamePreferences>(
                      create: (_) => GetIt.instance.get<GamePreferences>(),
                    ),
                    RepositoryProvider<LocalizationService>(
                      create: (_) => GetIt.instance.get<LocalizationService>(),
                    ),
                  ],
                  child: StreamBuilder<theme.Theme>(
                    stream: Stream.value(
                      theme.Theme(
                        backgroundImage: 'assets/images/backgrounds/bg_geo.png',
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
                              home: _buildAppHome(),
                            ),
                          )
                        : _showWaitForDataWidget(
                            snap, 'Fatal error: cannot load theme!'),
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

  Widget _showWaitForDataWidget(AsyncSnapshot snap, String errText) => Center(
      child: (snap.hasError
          ? Text(errText, textDirection: TextDirection.ltr)
          : CircularProgressIndicator()));

  Future<void> _initWithMigrations() => SharedPreferencesMigration()
      .migrateSharedPreferencesIfNeeded()
      .then((value) => GetIt.instance.allReady());
}
