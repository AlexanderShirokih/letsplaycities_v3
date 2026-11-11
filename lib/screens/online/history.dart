import 'package:flutter/material.dart';

import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/i18n/time_format.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/online/base_list_fetching_screen_mixin.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

/// Battle history list screen
/// Provides a list of user battle history
/// Requires the [ApiRepository] of the signed-in user in the widget tree.
class OnlineHistoryScreen extends StatelessWidget
    with BaseListFetchingScreenMixin<HistoryGame> {
  /// If `true` - a compact card of the games is shown instead of the list
  /// grouped by months
  final bool embedded;

  @override
  bool get scrollable => !embedded;

  @override
  UserFetchType get fetchEvent => UserFetchType.getHistoryList;

  /// Opponents id. If `null` then will showed all account owner history
  @override
  final int? withUser;

  /// Passed to the profiles of the opponents: the invitation of the open
  /// «Онлайн»
  final void Function(LpsUser friend)? onInvite;

  /// Header over the [embedded] card. Not shown with the card when there
  /// are no games.
  final String? embeddedTitle;

  const OnlineHistoryScreen({
    super.key,
    this.withUser,
    this.embedded = false,
    this.embeddedTitle,
    this.onInvite,
  });

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => embedded
      ? const SizedBox.shrink()
      : AppEmptyState(
          art: const AppTileArt(glyph: AppGlyph.history),
          title: context.t.online.historyEmptyTitle,
        );

  @override
  Widget buildItem(BuildContext context, HistoryGame data) =>
      _HistoryRow(game: data, onInvite: onInvite);

  @override
  Widget buildBody(
    BuildContext context,
    List<HistoryGame> data,
    bool hasMore,
    Object? moreError,
  ) {
    if (embedded) {
      final title = embeddedTitle;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                title,
                style: AppText.section.copyWith(color: AppColors.of(context).ink),
              ),
            ),
          _CompactGames(games: data),
        ],
      );
    }

    // Grouped on every build from all the loaded pages, so a month that
    // continues on the next page keeps its single header.
    final now = DateTime.now();
    final groups = <List<HistoryGame>>[];
    for (final game in data) {
      if (groups.isNotEmpty && _sameMonth(groups.last.first, game)) {
        groups.last.add(game);
      } else {
        groups.add([game]);
      }
    }
    final footer = buildPagingFooter(context, hasMore, moreError, data.length);
    final items = <Widget>[
      for (var i = 0; i < groups.length; i++) ...[
        if (i > 0) const SizedBox(height: 18),
        _MonthHeader(date: groups[i].first.startedAt, now: now),
        const SizedBox(height: 8),
        _RowsCard(
          rows: [for (final game in groups[i]) buildItem(context, game)],
        ),
      ],
      ?footer,
    ];

    // Built lazily, so the next page is asked for near the end of the list
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, i) => items[i],
    );
  }

  static bool _sameMonth(HistoryGame a, HistoryGame b) =>
      a.startedAt.year == b.startedAt.year &&
      a.startedAt.month == b.startedAt.month;
}

/// The year is left out for the current one
String _withYear(String text, DateTime date, DateTime now) =>
    date.year == now.year ? text : '$text ${date.year}';

class _MonthHeader extends StatelessWidget {
  final DateTime date;
  final DateTime now;

  const _MonthHeader({required this.date, required this.now});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      _withYear(context.t.online.months[date.month - 1], date, now),
      style: AppText.section.copyWith(color: AppColors.of(context).ink),
    ),
  );
}

/// [rows] in one card, divided by lines
class _RowsCard extends StatelessWidget {
  final List<Widget> rows;

  const _RowsCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Container(height: 2, color: c.bg),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final HistoryGame game;
  final void Function(LpsUser friend)? onInvite;

  const _HistoryRow({required this.game, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);
    final date = game.startedAt;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        OnlineProfileView.createRoute(
          context,
          userId: game.opponent.id,
          onInvite: onInvite,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 66),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  lpsUserAvatar(context, game.opponent),
                  if (game.isFriend)
                    Positioned(
                      right: -5,
                      bottom: -5,
                      child: Semantics(
                        label: t.online.friendMark,
                        child: Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.violet,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.surface, width: 2),
                          ),
                          child: AppIcon(
                            AppGlyph.check,
                            size: 11,
                            color: AppColors.light.surface,
                            strokeWidth: 3.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.opponent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(fontSize: 15, color: c.ink),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${t.online.wordsCount(count: game.words)}'
                      ' · ${formatMinutesSeconds(t, game.durationSec)}',
                      style: AppText.caption.copyWith(color: c.inkSoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${date.day} ${t.online.monthsShort[date.month - 1]}',
                style: AppText.caption.copyWith(color: c.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The games with one user in one card: date, words and duration
class _CompactGames extends StatelessWidget {
  final List<HistoryGame> games;

  const _CompactGames({required this.games});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);
    final now = DateTime.now();

    return _RowsCard(
      rows: [
        for (final game in games)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _withYear(
                        '${game.startedAt.day} '
                        '${t.online.monthsGenitive[game.startedAt.month - 1]}',
                        game.startedAt,
                        now,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(fontSize: 15, color: c.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.online.wordsCount(count: game.words),
                    style: AppText.bodyRegular.copyWith(
                      fontSize: 14,
                      color: c.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 76),
                    child: Text(
                      formatMinutesSeconds(t, game.durationSec),
                      textAlign: TextAlign.right,
                      style: AppText.bodyRegular.copyWith(
                        fontSize: 14,
                        color: c.inkSoft,
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
}
