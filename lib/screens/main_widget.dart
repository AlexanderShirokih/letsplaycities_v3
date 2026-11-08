import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_stream_listener/flutter_stream_listener.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as theme;
import 'package:lets_play_cities/base/themes/theme_manager.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/screens/main/main_screen.dart';
import 'package:lets_play_cities/screens/online/game_request_view.dart';

/// Application root class
class LetsPlayCitiesApp extends StatelessWidget {
  const LetsPlayCitiesApp({super.key});

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
              child: StreamBuilder<theme.Theme>(
                stream: getIt.get<ThemeManager>().currentTheme,
                initialData: getIt.get<ThemeManager>().fallback,
                builder: (_, snap) {
                  final currentTheme = snap.requireData;
                  final dark = getIt.get<ThemeManager>().dark;
                  return snap.hasData
                      ? MaterialApp(
                          locale: TranslationProvider.of(context).flutterLocale,
                          supportedLocales: AppLocaleUtils.supportedLocales,
                          localizationsDelegates:
                              GlobalMaterialLocalizations.delegates,
                          theme: _buildThemeData(
                            currentTheme.primaryColor,
                            currentTheme.isDark
                                ? Brightness.dark
                                : Brightness.light,
                            visualDensity:
                                VisualDensity.adaptivePlatformDensity,
                          ),
                          darkTheme: _buildThemeData(
                            dark.primaryColor,
                            Brightness.dark,
                          ),
                          builder: (_, child) => SystemBrightnessThemeProvider(
                            current: currentTheme,
                            dark: dark,
                            child: child!,
                          ),
                          home: _buildAppHome(),
                        )
                      : _showWaitForDataWidget(
                          snap,
                          'Fatal error: cannot load theme!',
                        );
                },
              ),
            )
          : _showWaitForDataWidget(
              snap,
              'Fatal error: cannot load root dependencies!',
            );
    },
  );

  ThemeData _buildThemeData(
    MaterialColor swatch,
    Brightness brightness, {
    VisualDensity? visualDensity,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: false,
      primarySwatch: swatch,
      brightness: brightness,
      visualDensity: visualDensity,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: swatch,
        accentColor: swatch,
        cardColor: isDark ? Colors.grey[800]! : Colors.white,
        backgroundColor: isDark ? Colors.grey[700]! : swatch[200]!,
        errorColor: Colors.red[700],
        brightness: brightness,
      ),
    );
  }

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

  Future<bool> _initDependencies() async {
    await GetIt.instance.allReady();

    return true;
  }
}

/// Provides the app [theme.Theme] for the current system brightness: [dark]
/// in dark mode, the user's [current] theme otherwise. Rebuilds when the
/// system brightness changes, like [MaterialApp] does when it switches to its
/// `darkTheme`.
class SystemBrightnessThemeProvider extends StatelessWidget {
  final theme.Theme current;
  final theme.Theme dark;
  final Widget child;

  const SystemBrightnessThemeProvider({
    super.key,
    required this.current,
    required this.dark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => RepositoryProvider<theme.Theme>.value(
    value: MediaQuery.platformBrightnessOf(context) == Brightness.dark
        ? dark
        : current,
    child: child,
  );
}
