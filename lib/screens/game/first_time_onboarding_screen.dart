import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';

/// Shows tips [strings] one by one with [duration] between them and then starts
/// [GameScreen], or goes back to the running game when it is a [replay] of
/// the rules.
class FirstTimeOnBoardingScreen extends StatefulWidget {
  final List<String> strings;
  final Duration duration;
  final GameConfig gameConfig;
  final bool replay;

  const FirstTimeOnBoardingScreen({
    super.key,
    required this.strings,
    required this.duration,
    required this.gameConfig,
    this.replay = false,
  });

  @override
  State<FirstTimeOnBoardingScreen> createState() =>
      _FirstTimeOnBoardingScreenState();
}

class _FirstTimeOnBoardingScreenState extends State<FirstTimeOnBoardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _currentTextId = 0;

  /// The screen is leaving: a tap during the route animation must not pop
  /// the game under it.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _controller.reset();
          if (_currentTextId < widget.strings.length - 1) {
            setState(() {
              _currentTextId++;
            });
          } else if (widget.replay) {
            if (!_leaving) Navigator.pop(context);
            _leaving = true;
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => GameScreen(widget.gameConfig)),
            );
          }
        }
      });
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

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
        // ignore: deprecated_member_use
        color: Theme.of(context).colorScheme.background,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  widget.strings[_currentTextId],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).textTheme.displaySmall!
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
