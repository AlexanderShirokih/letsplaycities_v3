import 'package:flutter/material.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/app_injection.dart';
import 'package:lets_play_cities/app_licenses.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/main_widget.dart';

/// Development entry point. The server comes from `--dart-define`, e.g.
/// `--dart-define=LPS_HOST=192.168.0.103 --dart-define=LPS_SECURE=false`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  injectRootDependencies(AppConfig.fromEnvironment());
  registerDataLicenses();

  runApp(TranslationProvider(child: LetsPlayCitiesApp()));
}
