// @dart=2.9

import 'package:flutter/material.dart';
import 'package:lets_play_cities/app_injection.dart';
import 'package:lets_play_cities/screens/main_widget.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  injectRootDependencies(
    serverHost: '194.87.111.204',
  );

  runApp(LetsPlayCitiesApp());
}
