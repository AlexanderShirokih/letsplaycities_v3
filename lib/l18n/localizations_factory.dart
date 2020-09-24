import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/l18n/mapped_localizations_service.dart';

class LocalizationsFactory {
  static const _LOCALIZATION_FILE = 'assets/i18n/strings.json';

  Future<LocalizationService> createDefaultLocalizations() async {
    final s = await rootBundle
        .loadString(_LOCALIZATION_FILE)
        .then((string) => jsonDecode(string))
        .then((json) => MappedLocalizationsService(json));
    return s;
  }
}
