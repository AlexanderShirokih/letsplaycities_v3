import 'package:flutter/widgets.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

/// Provides the typed strings that `context.t` reads to [child], as `main()`
/// does for the app. Widget tests wrap the widget they pump with it.
Widget withTranslations(Widget child) => TranslationProvider(child: child);
