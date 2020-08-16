import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/main_screen.dart';

void main() => runApp(LetsPlayCitiesApp());

/// Application root class
class LetsPlayCitiesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.orange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(body: MainScreen()),
      );
}
