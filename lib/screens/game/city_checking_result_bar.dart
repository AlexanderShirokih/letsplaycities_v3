import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/base/game/management/word_checking_result.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

class CityCheckingResultBar extends StatefulWidget {
  const CityCheckingResultBar({super.key});

  @override
  State<CityCheckingResultBar> createState() => _CityCheckingResultBarState();
}

class _CityCheckingResultBarState extends State<CityCheckingResultBar>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;
  late final GameSessionRepository _repository;
  late final StreamSubscription<WordCheckingResult> _results;
  WordCheckingResult? _result;
  bool completed = false;
  bool reverse = true;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );
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

    // Animates on new results only: a rebuild of the game layout must not
    // show an already dismissed message again.
    _repository = context.read<GameSessionRepository>();
    _results = _repository.wordCheckingResults.listen(_onResult);
  }

  void _onResult(WordCheckingResult result) {
    setState(() => _result = result);
    if (result.isDescriptiveError()) {
      _triggerAnimation();
    } else if (result is Corrections) {
      _triggerAnimation(reverse: false);
    }
  }

  void _triggerAnimation({bool reverse = true}) {
    completed = false;
    this.reverse = reverse;
    controller.forward();
  }

  @override
  void dispose() {
    _results.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result == null) return Container();

    if (result.isDescriptiveError()) {
      return SizeTransition(
        sizeFactor: animation,
        child: _createNotificationBox(
          context,
          _translateWordCheckingResult(context.t, result),
        ),
      );
    } else if (result is Corrections) {
      return SizeTransition(
        sizeFactor: animation,
        child: _showCorrectionsBox(
          context,
          _repository,
          result.corrections.toList(growable: false),
        ),
      );
    }
    return Container();
  }

  Widget _showCorrectionsBox(
    BuildContext context,
    GameSessionRepository repo,
    List<String> corrections,
  ) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.0),
    height: max(corrections.length * 62.0 + 30.0, 100),
    child: Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(
            context.t.game.corrections,
            style: Theme.of(context).textTheme.bodyMedium,
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
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );

  static String _translateWordCheckingResult(
    Translations t,
    WordCheckingResult data,
  ) {
    if (data is AlreadyUsed) {
      return t.game.alreadyUsed(city: data.word.toTitleCase());
    }
    if (data is WrongLetter) {
      return t.game.wrongLetter(letter: data.validLetter);
    }
    if (data is Exclusion) return data.description;
    if (data is NotFound) {
      return t.game.unknownCity(city: data.word.toTitleCase());
    }
    return '#501 Unknown state!';
  }
}
