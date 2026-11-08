import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';
import 'package:lets_play_cities/base/game/game_config.dart';

import 'cities_list.dart';
import 'input_fields.dart';
import 'score_panel.dart';
import 'top_bar.dart';

/// Top row, score, moves feed and input panel of a running game.
///
/// The feed keeps at least [minFeedHeight]: the input panel gets the rest of
/// the height below the score, and the word checking result scrolls in it.
///
/// Requires [GameSessionRepository], [GameServiceEventsRepository] and
/// [VoiceRecognitionBloc].
class GameLayout extends StatelessWidget {
  /// Room for one bubble of the feed
  static const minFeedHeight = 76.0;

  final GameConfig gameConfig;

  /// See [InputFieldsGroup.onRegisterInputClear]
  final ValueSetter<VoidCallback> onRegisterInputClear;

  /// Makes the score compact. Read above the [Scaffold]: its body does not
  /// see the bottom inset it resizes for.
  final bool keyboardOpen;

  const GameLayout(
    this.gameConfig, {
    super.key,
    required this.onRegisterInputClear,
    this.keyboardOpen = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SafeArea(bottom: false, child: TopBar(gameConfig)),
      ScorePanel(compact: keyboardOpen),
      Expanded(
        child: LayoutBuilder(
          builder: (context, box) => Column(
            children: [
              const CitiesList(),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: max(box.maxHeight - minFeedHeight, 0),
                ),
                child: InputFieldsGroup(
                  onRegisterInputClear: onRegisterInputClear,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
