import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/screens/main/main_screen.dart';

void main() => runApp(LetsPlayCitiesApp());

/// Application root class
class LetsPlayCitiesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<GamePreferences>.value(
        value: GamePreferences(),
        child: MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.orange,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: Scaffold(body: MainScreen()),
        ),
      );
}
