import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/word_checking_result.dart';

import 'package:lets_play_cities/base/repos.dart';

class CityCheckingResultBar extends StatefulWidget {
  @override
  State<CityCheckingResultBar> createState() => _CityCheckingResultBarState();
}

class _CityCheckingResultBarState extends State<CityCheckingResultBar>
    with TickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;
  bool completed = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 2200), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCirc);

    animation.addStatusListener((status) {
      if (completed) return;

      if (status == AnimationStatus.completed) {
        controller.reverse();
        completed = true;
      } else if (status == AnimationStatus.dismissed) {
        controller.forward();
      }
    });
  }

  void _triggerAnimation() {
    completed = false;
    controller.forward();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WordCheckingResult>(
      stream: context.repository<GameSessionRepository>().wordCheckingResults,
      builder: (context, snapshot) {
        String message = "";
        if (snapshot.hasData && snapshot.data.isDescriptiveError()) {
          _triggerAnimation();
          message = _translateWordCheckingResult(snapshot.data);
        }
        return SizeTransition(
          sizeFactor: animation,
          child: Container(
            margin: EdgeInsets.all(8.0),
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            height: 42.0,
            color: Theme.of(context).secondaryHeaderColor,
            child: Row(
              children: [
                Icon(Icons.warning),
                SizedBox(width: 12.0),
                Expanded(
                  child: Text(message),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  String _translateWordCheckingResult(WordCheckingResult data) {
    if (data is AlreadyUsed) return "Город ${data.word} уже был загадан";
    if (data is WrongLetter)
      return "Город должен начинаться на букву ${data.validLetter}";
    if (data is Exclusion) return data.description;
    if (data is NotFound)
      return "Очень жаль, но нам неизвестен город ${data.word}.\nПроверьте правильность написания";
    return "#501 Unknown state!";
  }
}
