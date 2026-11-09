import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game_results/results_parts.dart';

/// Size of the picture in logical pixels: 1080x1440 pixels
const gameShareCardSize = Size(360, 480);

/// The picture of a finished game: result, score of the players, cities,
/// time, the longest city and the best combos
class GameShareCard extends StatelessWidget {
  final GameResult result;

  const GameShareCard(this.result, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final t = context.t;
    final summary = result.summary;
    final opponent = result.opponent;
    final combos = bestCombosOf(summary);

    return SizedBox.fromSize(
      size: gameShareCardSize,
      child: ColoredBox(
        color: c.bg,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const D2Logo(size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.matchResult.label(t),
                      overflow: TextOverflow.ellipsis,
                      style: D2Text.title.copyWith(fontSize: 22, color: c.ink),
                    ),
                  ),
                ],
              ),
              if (result.hasScore) ...[
                const SizedBox(height: 14),
                D2Card(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      _row(context, result.owner, c.violet),
                      if (opponent != null) ...[
                        const SizedBox(height: 4),
                        _row(context, opponent, c.letter),
                      ],
                    ],
                  ),
                ),
              ],
              if (summary.citiesCount > 0) ...[
                const SizedBox(height: 12),
                ResultMetrics(summary),
              ],
              if (combos.isNotEmpty) ...[
                const SizedBox(height: 12),
                ResultCombos(combos),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, User user, Color scoreColor) {
    final c = D2Colors.of(context);

    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Expanded(
            child: Text(
              user.name,
              overflow: TextOverflow.ellipsis,
              style: D2Text.body.copyWith(fontSize: 15, color: c.ink),
            ),
          ),
          Text(
            '${user.score}',
            style: D2Text.score.copyWith(fontSize: 22, color: scoreColor),
          ),
        ],
      ),
    );
  }
}
