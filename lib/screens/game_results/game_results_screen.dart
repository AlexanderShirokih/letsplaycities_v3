import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/ads/advertising_helper.dart';
import 'package:lets_play_cities/base/game/combo.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/base/game/game_result.dart';
import 'package:lets_play_cities/base/game/game_summary.dart';
import 'package:lets_play_cities/base/platform/share.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/enum_labels.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/remote_player.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';
import 'package:lets_play_cities/screens/game/combo_badge.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/game/hotseat_setup_screen.dart';
import 'package:lets_play_cities/screens/game/user_avatar.dart';
import 'package:lets_play_cities/screens/online/profile.dart';
import 'package:lets_play_cities/utils/minutes_seconds.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// How many combos the results show
const _kBestCombosCount = 3;

/// Shows when the game ends
class GameResultsScreen extends StatefulWidget {
  final GameResult _gameResult;

  final GameConfig _gameConfig;

  const GameResultsScreen(this._gameResult, this._gameConfig, {super.key});

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen> {
  GameResult get _gameResult => widget._gameResult;

  GameConfig get _gameConfig => widget._gameConfig;

  GameSummary get _summary => _gameResult.summary;

  @override
  void initState() {
    super.initState();
    // Once per screen: build() runs again on every theme, locale or layout
    // change. Ad errors are not shown to the user.
    GetIt.instance.get<AdManager>().showInterstitial().ignore();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: Stack(
        children: [
          const Align(alignment: Alignment.topCenter, child: _Confetti()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 36, 16, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context, t),
                        if (_gameResult.hasScore) ...[
                          const SizedBox(height: 16),
                          _buildScoreCard(context),
                        ],
                        if (_summary.citiesCount > 0) ...[
                          const SizedBox(height: 12),
                          _buildMetrics(context, t),
                        ],
                        ..._buildCombos(context, t),
                        ..._buildRemoteOpponents(context, t),
                        const SizedBox(height: 16),
                        const Spacer(),
                        _buildButtons(context, t),
                      ],
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

  Widget _buildHeader(BuildContext context, Translations t) {
    final c = D2Colors.of(context);
    final glyph = switch (_gameResult.matchResult) {
      MatchResult.win => D2Glyph.trophy,
      MatchResult.lose => D2Glyph.surrender,
      MatchResult.draw => D2Glyph.check,
    };

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: c.yellow,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: c.shadow.withAlpha(56),
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: D2Icon(
            glyph,
            size: 38,
            color: D2Colors.light.ink,
            strokeWidth: 2.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _gameResult.matchResult.label(t),
          textAlign: TextAlign.center,
          style: D2Text.display.copyWith(fontSize: 30, color: c.ink),
        ),
        const SizedBox(height: 6),
        Text(
          _gameResult.finishType.finishDescription(
            t,
            _gameResult.finishRequester.name,
          ),
          textAlign: TextAlign.center,
          style: D2Text.bodyRegular.copyWith(color: c.inkSoft),
        ),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context) {
    final c = D2Colors.of(context);
    final opponent = _gameResult.opponent;

    return D2Card(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          _ScoreRow(_gameResult.owner, c.violet),
          if (opponent != null) ...[
            const SizedBox(height: 6),
            Container(height: 2, color: c.bg),
            const SizedBox(height: 6),
            _ScoreRow(opponent, c.letter),
          ],
        ],
      ),
    );
  }

  Widget _buildMetrics(BuildContext context, Translations t) {
    final c = D2Colors.of(context);
    final longest = _summary.longestCity;

    return D2Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: t.gameResults.cities,
                    value: Text(
                      '${_summary.citiesCount}',
                      style: D2Text.title.copyWith(fontSize: 20, color: c.ink),
                    ),
                  ),
                ),
                Container(width: 2, color: c.bg),
                Expanded(
                  child: _Metric(
                    label: t.gameResults.time,
                    value: Text(
                      formatClock(_summary.duration.inSeconds),
                      style: D2Text.title.copyWith(fontSize: 20, color: c.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (longest != null) ...[
            Container(height: 2, color: c.bg),
            _Metric(
              label: t.gameResults.longestCity,
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (longest.countryCode > 0) ...[
                    CityFlag(longest.countryCode),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text.rich(
                      cityNameSpans(longest.city.toTitleCase(), c),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Iterable<Widget> _buildCombos(BuildContext context, Translations t) sync* {
    final best =
        (_summary.bestCombos.entries.where((e) => e.value > 0).toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(_kBestCombosCount);

    if (best.isEmpty) return;

    yield const SizedBox(height: 16);
    yield Text(
      t.gameResults.comboTitle,
      style: D2Text.section.copyWith(color: D2Colors.of(context).ink),
    );
    yield const SizedBox(height: 8);
    yield IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, e) in best.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _ComboCard(e.key, e.value)),
          ],
        ],
      ),
    );
  }

  Iterable<Widget> _buildRemoteOpponents(
    BuildContext context,
    Translations t,
  ) sync* {
    if (_gameConfig.gameMode != GameMode.network) return;

    final opponents = _getRemoteOpponents().toList();

    if (opponents.isEmpty) return;

    final c = D2Colors.of(context);

    yield const SizedBox(height: 16);
    yield Text(
      t.gameResults.youPlayedWith,
      style: D2Text.section.copyWith(color: c.ink),
    );

    for (final opp in opponents) {
      yield const SizedBox(height: 8);
      yield GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnlineProfileViewStandalone(
              (opp.accountInfo as AdvancedAccountInfo).userId,
            ),
          ),
        ),
        child: D2Card(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              buildD2AvatarForUser(opp, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  opp.accountInfo.name,
                  overflow: TextOverflow.ellipsis,
                  style: D2Text.body.copyWith(fontSize: 15, color: c.ink),
                ),
              ),
              const SizedBox(width: 10),
              D2Icon(D2Glyph.more, size: 20, color: c.inkSoft),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildButtons(BuildContext context, Translations t) {
    final canShare = _gameResult.hasScore && _gameResult.owner.score > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        D2Button(
          label: t.gameResults.playAgain,
          icon: D2Glyph.replay,
          size: D2ButtonSize.large,
          expand: true,
          onPressed: () => _gameConfig.gameMode.isLocal
              ? Navigator.pushReplacement(context, _replayRoute(_gameConfig))
              : (_gameConfig.gameMode == GameMode.multiplayer
                    ? Navigator.popUntil(
                        context,
                        (route) => route.settings.name == 'multiplayer',
                      )
                    : Navigator.pop(context)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: D2Button(
                label: t.gameResults.toMenu,
                icon: D2Glyph.exit,
                kind: D2ButtonKind.secondary,
                expand: true,
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
            ),
            if (canShare) ...[
              const SizedBox(width: 10),
              Expanded(
                child: D2Button(
                  label: t.gameResults.share,
                  icon: D2Glyph.share,
                  kind: D2ButtonKind.secondary,
                  expand: true,
                  onPressed: () => Share.text(
                    t.gameResults.shareScore(score: _gameResult.owner.score),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Iterable<RemotePlayer> _getRemoteOpponents() {
    return _gameConfig.usersListOverride?.all
            .where((user) => user != _gameResult.owner && user is RemotePlayer)
            .cast<RemotePlayer>() ??
        <RemotePlayer>[];
  }
}

/// A new local game: two players on one phone confirm their names and who
/// moves first before it.
Route<dynamic> _replayRoute(GameConfig config) =>
    config.gameMode == GameMode.playerVsPlayer
    ? MaterialPageRoute<void>(builder: (_) => const HotseatSetupScreen())
    : GameScreen.createGameScreenRoute(config);

/// Avatar, name and score of one user
class _ScoreRow extends StatelessWidget {
  final User user;
  final Color scoreColor;

  const _ScoreRow(this.user, this.scoreColor);

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          buildD2AvatarForUser(user, size: 32),
          const SizedBox(width: 10),
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

/// A [value] with its [label] below
class _Metric extends StatelessWidget {
  final String label;
  final Widget value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 11),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          value,
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: D2Text.small.copyWith(
              fontWeight: FontWeight.w400,
              color: c.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// The best level of one combo type
class _ComboCard extends StatelessWidget {
  final ComboType type;
  final int level;

  const _ComboCard(this.type, this.level);

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final t = context.t;
    final tile = switch (type) {
      ComboType.quickTime => c.yellow,
      ComboType.shortWord => c.sky,
      ComboType.longWord => c.orange,
      ComboType.sameCountry => c.edge,
      ComboType.differentCountries => c.mint,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tile,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: D2Icon(
              ComboBadgeWidget.glyphOf(type),
              size: 22,
              color: D2Colors.light.ink,
              strokeWidth: 2.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            type.label(t),
            style: D2Text.small.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.gameResults.comboTimes(count: ComboSystem.badgeValue(level)),
            style: D2Text.small.copyWith(
              fontWeight: FontWeight.w400,
              color: c.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// Static confetti over the header, 360x170 as in the mockup
class _Confetti extends StatelessWidget {
  const _Confetti();

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(360, 170),
        painter: _ConfettiPainter(
          orange: c.orange,
          yellow: c.yellow,
          mint: c.mint,
          violet: c.violet,
          sky: c.sky,
          ink: c.shadow,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Color orange;
  final Color yellow;
  final Color mint;
  final Color violet;
  final Color sky;
  final Color ink;

  const _ConfettiPainter({
    required this.orange,
    required this.yellow,
    required this.mint,
    required this.violet,
    required this.sky,
    required this.ink,
  });

  @override
  void paint(Canvas canvas, Size size) {
    rect(40, 52, 14, 9, orange, 20, 47, 56, canvas);
    circle(84, 34, 6, yellow, canvas);
    rect(70, 104, 12, 12, mint, -15, 76, 110, canvas);
    triangle(286, 44, violet, 20, 286, 51, canvas);
    rect(306, 100, 16, 10, sky, -30, 314, 105, canvas);
    circle(256, 30, 5, orange, canvas);
    circle(24, 98, 4, violet, canvas);
    rect(250, 120, 10, 10, yellow, 35, 255, 125, canvas);
    circle(336, 62, 4, mint, canvas);
    triangle(112, 70, orange, -25, 112, 75, canvas);
  }

  void _draw(Canvas canvas, Path path, Color fill) {
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = ink,
    );
  }

  void _rotated(
    Canvas canvas,
    double degrees,
    double cx,
    double cy,
    void Function() draw,
  ) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(degrees * 3.1415926535897932 / 180);
    canvas.translate(-cx, -cy);
    draw();
    canvas.restore();
  }

  void rect(
    double x,
    double y,
    double w,
    double h,
    Color fill,
    double degrees,
    double cx,
    double cy,
    Canvas canvas,
  ) => _rotated(
    canvas,
    degrees,
    cx,
    cy,
    () => _draw(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w, h),
          const Radius.circular(2.5),
        ),
      ),
      fill,
    ),
  );

  void circle(double cx, double cy, double r, Color fill, Canvas canvas) =>
      _draw(
        canvas,
        Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
        fill,
      );

  /// The triangle of the mockup: M x y l 7 14 h -14 z
  void triangle(
    double x,
    double y,
    Color fill,
    double degrees,
    double cx,
    double cy,
    Canvas canvas,
  ) => _rotated(
    canvas,
    degrees,
    cx,
    cy,
    () => _draw(
      canvas,
      Path()
        ..moveTo(x, y)
        ..relativeLineTo(7, 14)
        ..relativeLineTo(-14, 0)
        ..close(),
      fill,
    ),
  );

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.orange != orange ||
      old.yellow != yellow ||
      old.mint != mint ||
      old.violet != violet ||
      old.sky != sky ||
      old.ink != ink;
}
