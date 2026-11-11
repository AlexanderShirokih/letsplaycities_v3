import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

/// «Ход N из 15» and a segment per move: done ones violet, the current one
/// yellow, the rest empty.
class RouteProgress extends StatelessWidget {
  /// The number of the current move, from 1
  final int move;

  final int total;

  const RouteProgress({super.key, required this.move, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            context.t.route.move(n: move, total: total),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.section.copyWith(fontSize: 13, color: c.ink),
          ),
        ),
        const SizedBox(width: 8),
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= total; i++) ...[
                if (i > 1) const SizedBox(width: 3),
                _segment(c, i),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _segment(AppColors c, int index) {
    final current = index == move;

    return Container(
      width: 7,
      height: 8,
      decoration: BoxDecoration(
        color: current
            ? c.yellow
            : index < move
            ? c.violet
            : c.edge,
        borderRadius: BorderRadius.circular(2),
        border: current
            ? Border.all(
                color: c.ink,
                width: 2,
                strokeAlign: BorderSide.strokeAlignCenter,
              )
            : null,
      ),
    );
  }
}
