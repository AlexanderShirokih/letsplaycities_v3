import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_stream_listener/flutter_stream_listener.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/screens/common/theme_mode.dart';
import 'package:lets_play_cities/base/themes/app_theme_mode.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/root/root_screen.dart';
import 'package:lets_play_cities/screens/online/game_request_view.dart';

/// Application root class
class LetsPlayCitiesApp extends StatefulWidget {
  const LetsPlayCitiesApp({super.key});

  @override
  State<LetsPlayCitiesApp> createState() => _LetsPlayCitiesAppState();
}

class _LetsPlayCitiesAppState extends State<LetsPlayCitiesApp> {
  /// The main server's connection and API, taken from the root scope when
  /// the app starts: pushes are answered there also inside a LAN game
  GameConnection? _connection;
  ApiRepositoryFactory? _apiRepositories;

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _initDependencies(),
    builder: (context, snap) {
      final getIt = GetIt.instance;
      return snap.hasData
          ? MultiRepositoryProvider(
              providers: [
                RepositoryProvider<GamePreferences>(
                  create: (_) => getIt.get<GamePreferences>(),
                ),
              ],
              child: ValueListenableBuilder<AppThemeMode>(
                valueListenable: getIt.get<ValueNotifier<AppThemeMode>>(
                  instanceName: themeModeNotifierName,
                ),
                builder: (_, mode, _) => MaterialApp(
                  locale: TranslationProvider.of(context).flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  theme: buildAppTheme(Brightness.light),
                  darkTheme: buildAppTheme(Brightness.dark),
                  themeMode: mode.asThemeMode,
                  home: _buildAppHome(),
                ),
              ),
            )
          : _showWaitForDataWidget(
              snap,
              'Fatal error: cannot load root dependencies!',
            );
    },
  );

  Widget _buildAppHome() {
    final getIt = GetIt.instance;
    _connection ??= getIt.get<GameConnection>();
    _apiRepositories ??= getIt.get<ApiRepositoryFactory>();

    return _buildHomeScaffold(_connection!, _apiRepositories!);
  }

  Widget _buildHomeScaffold(
    GameConnection connection,
    ApiRepositoryFactory apiRepositories,
  ) => Scaffold(
    body: Builder(
      builder: (context) => StreamListener<GameRequest>(
        stream: GetIt.instance
            .get<CloudMessagingService>()
            .messages
            .where((event) => event is GameRequest)
            .cast<GameRequest>(),
        onData: (request) {
          showAppSheet<void>(
            context,
            builder: (_) => GameRequestView(
              request: request,
              connection: connection,
              apiRepositories: apiRepositories,
            ),
          );
        },
        child: SafeArea(child: const RootScreen()),
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

  Future<bool> _initDependencies() async {
    await GetIt.instance.allReady();

    return true;
  }
}
