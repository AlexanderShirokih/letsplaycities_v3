import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';

/// Shows tips [strings] one by one with [duration] between them and then starts
/// [GameScreen]
class FirstTimeOnBoardingScreen extends StatefulWidget {
  final List<String> strings;
  final Duration duration;
  final GameConfig gameConfig;

  const FirstTimeOnBoardingScreen({
    required this.strings,
    required this.duration,
    required this.gameConfig,
  });

  @override
  _FirstTimeOnBoardingScreenState createState() =>
      _FirstTimeOnBoardingScreenState(strings, duration, gameConfig);
}

class _FirstTimeOnBoardingScreenState extends State<FirstTimeOnBoardingScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _strings;
  final Duration _duration;
  final GameConfig _gameConfig;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _currentTextId = 0;

  _FirstTimeOnBoardingScreenState(
      this._strings, this._duration, this._gameConfig);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: _duration,
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          if (_currentTextId < _strings.length - 1) {
            setState(() {
              _currentTextId++;
            });
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => GameScreen(_gameConfig)));
          }
        }
      });
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(curved);
    _scaleAnimation = Tween(begin: 0.98, end: 1.0).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _controller.forward();
    return GestureDetector(
      onTap: () {
        // Speed up animation
        _controller.forward(from: 0.99);
      },
      child: Container(
        color: Theme.of(context).backgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  _strings[_currentTextId],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context)
                      .textTheme
                      .headline3!
                      .copyWith(fontWeight: FontWeight.w800),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
