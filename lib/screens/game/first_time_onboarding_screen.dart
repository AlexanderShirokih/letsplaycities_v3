import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';

/// Shows tips [strings] one by one with [duration] between them and then starts
/// [GameScreen]
class FirstTimeOnBoardingScreen extends StatefulWidget {
  final List<String> strings;
  final Duration duration;
  final GameMode gameMode;

  const FirstTimeOnBoardingScreen({
    @required this.strings,
    @required this.duration,
    @required this.gameMode,
  })  : assert(strings != null),
        assert(duration != null),
        assert(gameMode != null);

  @override
  _FirstTimeOnBoardingScreenState createState() =>
      _FirstTimeOnBoardingScreenState(strings, duration, gameMode);
}

class _FirstTimeOnBoardingScreenState extends State<FirstTimeOnBoardingScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _strings;
  final Duration _duration;
  final GameMode _gameMode;

  AnimationController _controller;
  Animation<double> _fadeAnimation;
  Animation<double> _scaleAnimation;

  int _currentTextId = 0;

  _FirstTimeOnBoardingScreenState(
      this._strings, this._duration, this._gameMode);

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
                MaterialPageRoute(builder: (_) => GameScreen(_gameMode)));
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
    return Container(
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
                    .headline3
                    .copyWith(fontWeight: FontWeight.w800),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
