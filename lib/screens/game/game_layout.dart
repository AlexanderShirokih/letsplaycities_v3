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

  /// Height of the input panel without the word checking result: the top
  /// border, the paddings and the field
  static const minInputHeight = 85.0;

  /// A row of the word checking result: the caption and the corrections
  static const resultHeight = 76.0;

  final GameConfig gameConfig;

  /// See [InputFieldsGroup.onRegisterInputClear]
  final ValueSetter<VoidCallback> onRegisterInputClear;

  const GameLayout(
    this.gameConfig, {
    super.key,
    required this.onRegisterInputClear,
  });

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SafeArea(bottom: false, child: TopBar(gameConfig)),
      Expanded(
        child: LayoutBuilder(
          builder: (context, box) => Column(
            children: [
              // Full size while the keyboard is open; only a screen too short
              // for the feed, the input and its result scales the score down
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: max(
                    box.maxHeight -
                        minFeedHeight -
                        minInputHeight -
                        resultHeight,
                    0,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: box.maxWidth,
                    child: const ScorePanel(),
                  ),
                ),
              ),
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
          ),
        ),
      ),
    ],
  );
}
