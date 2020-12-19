import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/game/management/word_checking_result.dart';
import 'package:lets_play_cities/utils/string_utils.dart';
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
  bool reverse = true;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
        duration: const Duration(milliseconds: 2200), vsync: this);
    animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCirc);

    animation.addStatusListener((status) {
      if (completed) return;

      if (status == AnimationStatus.completed) {
        if (reverse) controller.reverse();
        completed = true;
        reverse = true;
      } else if (status == AnimationStatus.dismissed) {
        controller.forward();
      }
    });
  }

  void _triggerAnimation({bool reverse = true}) {
    completed = false;
    this.reverse = reverse;
    controller.forward();
  }

  @override
  void dispose() {
    super.dispose();
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GameSessionRepository>();
    return StreamBuilder<WordCheckingResult>(
      stream: repo.wordCheckingResults,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();

        if (snapshot.data.isDescriptiveError()) {
          _triggerAnimation();
          return SizeTransition(
            sizeFactor: animation,
            child: _createNotificationBox(
                context, _translateWordCheckingResult(snapshot.data)),
          );
        } else if (snapshot.data is Corrections) {
          _triggerAnimation(reverse: false);
          return SizeTransition(
            sizeFactor: animation,
            child: _showCorrectionsBox(
              context,
              repo,
              (snapshot.data as Corrections)
                  .corrections
                  .toList(growable: false),
            ),
          );
        }
        return Container();
        // Another way
      },
    );
  }

  Widget _showCorrectionsBox(
    BuildContext context,
    GameSessionRepository repo,
    List<String> corrections,
  ) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        height: max(corrections.length * 64.0 + 30.0, 100),
        color: Theme.of(context).secondaryHeaderColor,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                'Варианты исправления',
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: min(corrections.length, 5),
                itemBuilder: (context, index) => Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListTile(
                    onTap: () => repo.sendInputWord(corrections[index]),
                    title: Text(corrections[index].toTitleCase()),
                    leading: FaIcon(FontAwesomeIcons.city),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _createNotificationBox(BuildContext context, String message) =>
      Container(
        margin: const EdgeInsets.all(8.0),
        color: Theme.of(context).secondaryHeaderColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
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

  static String _translateWordCheckingResult(WordCheckingResult data) {
    if (data is AlreadyUsed) {
      return 'Город ${data.word.toTitleCase()} уже был загадан';
    }
    if (data is WrongLetter) {
      return 'Город должен начинаться на букву ${data.validLetter}';
    }
    if (data is Exclusion) return data.description;
    if (data is NotFound) {
      return 'Очень жаль, но нам неизвестен город ${data.word.toTitleCase()}.\nПроверьте правильность написания';
    }
    return '#501 Unknown state!';
  }
}
