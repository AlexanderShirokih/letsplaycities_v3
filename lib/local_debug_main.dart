import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_injection.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/screens/main_widget.dart';

import 'remote/auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  injectRootDependencies(
    serverHost: '192.168.0.103',
  );

  // Mock development account
  GetIt.instance.getAsync<GamePreferences>().then(
    (prefs) {
      prefs.setCurrentCredentials(Credential(
        userId: 39387,
        accessToken: 'n0U2ysM9',
      ));
    },
  );

  runApp(LetsPlayCitiesApp());
}
