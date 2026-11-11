import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/management/word_checking_result.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// The error of the word checking under the input field, or the corrections
/// of the word.
class CityCheckingResultBar extends StatefulWidget {
  /// Set to `true` while an error message is shown
  final ValueNotifier<bool>? errorShown;

  const CityCheckingResultBar({super.key, this.errorShown});

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
      if (status == AnimationStatus.dismissed) _setErrorShown(false);
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
    _setErrorShown(result.isDescriptiveError());
    if (result.isDescriptiveError()) {
      _triggerAnimation();
    } else if (result is Corrections) {
      _triggerAnimation(reverse: false);
    }
  }

  void _setErrorShown(bool shown) {
    final notifier = widget.errorShown;
    if (notifier != null) notifier.value = shown;
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

  /// At most five [corrections] in one row that scrolls sideways, so that
  /// they fit above the keyboard
  Widget _showCorrectionsBox(
    BuildContext context,
    GameSessionRepository repo,
    List<String> corrections,
  ) {
    final c = AppColors.of(context);
    final radius = BorderRadius.circular(14);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t.game.corrections,
            style: AppText.body.copyWith(fontSize: 13, color: c.inkSoft),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (i, correction) in corrections.take(5).indexed)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                    child: Material(
                      color: c.bg,
                      borderRadius: radius,
                      child: InkWell(
                        borderRadius: radius,
                        onTap: () => repo.sendInputWord(correction),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 44),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          child: Text(
                            correction.toTitleCase(),
                            maxLines: 1,
                            style: AppText.body.copyWith(color: c.ink),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _createNotificationBox(BuildContext context, String message) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(AppGlyph.warning, size: 18, color: c.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppText.body.copyWith(fontSize: 14, color: c.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
