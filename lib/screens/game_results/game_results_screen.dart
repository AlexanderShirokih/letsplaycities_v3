import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/game/hotseat_setup_screen.dart';
import 'package:lets_play_cities/screens/game/user_avatar.dart';
import 'package:lets_play_cities/screens/game_results/game_share_card.dart';
import 'package:lets_play_cities/screens/game_results/results_parts.dart';
import 'package:lets_play_cities/screens/game_results/share_image.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

/// Shows when the game ends
class GameResultsScreen extends StatefulWidget {
  final GameResult _gameResult;

  final GameConfig _gameConfig;

  /// Called by the button that shares the result; the result picture with
  /// the text is shared when not set
  final Future<void> Function(BuildContext context)? onShare;

  const GameResultsScreen(
    this._gameResult,
    this._gameConfig, {
    super.key,
    this.onShare,
  });

  @override
  State<GameResultsScreen> createState() => _GameResultsScreenState();
}

class _GameResultsScreenState extends State<GameResultsScreen> {
  GameResult get _gameResult => widget._gameResult;

  GameConfig get _gameConfig => widget._gameConfig;

  GameSummary get _summary => _gameResult.summary;

  /// Set while the picture is rendered and shared: more taps are ignored
  var _sharing = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Scaffold(
      body: _celebrate(
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
                        ResultMetrics(_summary),
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
      ),
    );
  }

  /// A celebration only of a win
  Widget _celebrate(Widget content) =>
      _gameResult.matchResult == MatchResult.win
      ? _Confetti(child: content)
      : content;

  Widget _buildHeader(BuildContext context, Translations t) {
    final c = D2Colors.of(context);
    final (glyph, tile) = switch (_gameResult.matchResult) {
      MatchResult.win => (D2Glyph.trophy, c.yellow),
      MatchResult.lose => (D2Glyph.surrender, c.yellow),
      MatchResult.draw => (D2Glyph.equal, c.sky),
    };

    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: tile,
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

  Iterable<Widget> _buildCombos(BuildContext context, Translations t) sync* {
    final best = bestCombosOf(_summary);

    if (best.isEmpty) return;

    yield const SizedBox(height: 16);
    yield Text(
      t.gameResults.comboTitle,
      style: D2Text.section.copyWith(color: D2Colors.of(context).ink),
    );
    yield const SizedBox(height: 8);
    yield ResultCombos(best);
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
              ? Navigator.pushReplacement(context, replayRoute(_gameConfig))
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
                  onPressed: _onSharePressed,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Shares the result once at a time and tells the user when it fails
  Future<void> _onSharePressed() async {
    if (_sharing) return;

    _sharing = true;
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.t.route.shareFailed;

    try {
      await (widget.onShare ?? _share)(context);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      _sharing = false;
    }
  }

  /// Renders the result picture and shares it with the text
  Future<void> _share(BuildContext context) async {
    final text = context.t.gameResults.shareScore(
      score: _gameResult.owner.score,
    );
    final path = await renderShareImage(
      context,
      GameShareCard(_gameResult),
      size: gameShareCardSize,
      fileName: 'game_share.png',
    );

    await Share.image(path, text);
  }

  Iterable<RemotePlayer> _getRemoteOpponents() {
    return _gameConfig.usersListOverride?.all
            .where((user) => user != _gameResult.owner && user is RemotePlayer)
            .cast<RemotePlayer>() ??
        <RemotePlayer>[];
  }
}

/// A new local game: two players on one phone confirm their names and who
/// moves first before it. The results of every variant replay through it.
Route<dynamic> replayRoute(GameConfig config) =>
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

/// Confetti of a win, 360x170 over the header as in the mockup: the pieces
/// burst out of the trophy into their places and keep turning there
class _Confetti extends StatefulWidget {
  /// The screen over the confetti
  final Widget child;

  const _Confetti({required this.child});

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  /// Seconds since the screen opened
  final _time = ValueNotifier<double>(0);

  late final _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      // The pieces in their places, still
      _ticker.stop();
      _time.value = _MockupConfettiPainter.burst;
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ConfettiColors.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ExcludeSemantics(
            child: CustomPaint(
              size: const Size(360, 170),
              painter: _MockupConfettiPainter(
                colors,
                _time,
                // The middle of the trophy tile, under the safe area
                Offset(180, MediaQuery.paddingOf(context).top + 70),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _ConfettiColors {
  final List<Color> fills;
  final Color ink;

  _ConfettiColors(this.fills, this.ink);

  factory _ConfettiColors.of(BuildContext context) {
    final c = D2Colors.of(context);

    return _ConfettiColors([
      c.orange,
      c.yellow,
      c.mint,
      c.violet,
      c.sky,
    ], c.shadow);
  }

  Color get orange => fills[0];

  Color get yellow => fills[1];

  Color get mint => fills[2];

  Color get violet => fills[3];

  Color get sky => fills[4];

  @override
  bool operator ==(Object other) =>
      other is _ConfettiColors &&
      other.ink == ink &&
      listEquals(other.fills, fills);

  @override
  int get hashCode => Object.hash(ink, Object.hashAll(fills));
}

/// A piece outlined in [ink] as in the mockup
void _drawPiece(Canvas canvas, Path path, Color fill, Color ink) {
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

Path _rectPath(double x, double y, double w, double h) => Path()
  ..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(2.5),
    ),
  );

Path _circlePath(double cx, double cy, double r) =>
    Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

/// The triangle of the mockup: M x y l 7 14 h -14 z
Path _trianglePath(double x, double y) => Path()
  ..moveTo(x, y)
  ..relativeLineTo(7, 14)
  ..relativeLineTo(-14, 0)
  ..close();

/// The confetti of the mockup. The pieces start hidden behind the trophy
/// at [origin] and fly out to their places, growing and turning. Then each
/// one keeps turning slowly and bobbing a little
class _MockupConfettiPainter extends CustomPainter {
  final _ConfettiColors c;

  /// Seconds since the screen opened
  final ValueListenable<double> time;

  final Offset origin;

  _MockupConfettiPainter(this.c, this.time, this.origin) : super(repaint: time);

  /// Seconds the burst lasts
  static const burst = 0.75;

  /// The pieces as the mockup draws them: path, fill, rotation in degrees
  /// and the point it turns around
  List<(Path, Color, double, Offset)> get _pieces => [
    (_rectPath(40, 52, 14, 9), c.orange, 20, const Offset(47, 56)),
    (_circlePath(84, 34, 6), c.yellow, 0, const Offset(84, 34)),
    (_rectPath(70, 104, 12, 12), c.mint, -15, const Offset(76, 110)),
    (_trianglePath(286, 44), c.violet, 20, const Offset(286, 51)),
    (_rectPath(306, 100, 16, 10), c.sky, -30, const Offset(314, 105)),
    (_circlePath(256, 30, 5), c.orange, 0, const Offset(256, 30)),
    (_circlePath(24, 98, 4), c.violet, 0, const Offset(24, 98)),
    (_rectPath(250, 120, 10, 10), c.yellow, 35, const Offset(255, 125)),
    (_circlePath(336, 62, 4), c.mint, 0, const Offset(336, 62)),
    (_trianglePath(112, 70), c.orange, -25, const Offset(112, 75)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pieces = _pieces;

    final seconds = time.value;
    final progress = (seconds / burst).clamp(0.0, 1.0);
    final after = math.max(0.0, seconds - burst);

    for (var i = 0; i < pieces.length; i++) {
      final (path, fill, degrees, center) = pieces[i];
      final start = i * 0.02;
      final t = Interval(
        start,
        start + 0.8,
        curve: Curves.easeOutCubic,
      ).transform(progress);

      // Each piece turns at its own pace, half of them the other way
      final direction = i.isEven ? 1 : -1;
      final turning = direction * (0.7 + (i % 3) * 0.35) * after;
      final bob = 3 * math.sin(after * 2.4 + i) * math.min(1.0, after);

      final position = Offset.lerp(origin, center, t)! + Offset(0, bob);
      final spin = (1 - t) * direction * 0.5 * math.pi + turning;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(degrees * math.pi / 180 + spin);
      canvas.scale(0.3 + 0.7 * t);
      canvas.translate(-center.dx, -center.dy);
      _drawPiece(canvas, path, fill, c.ink);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_MockupConfettiPainter old) =>
      old.c != c || old.time != time || old.origin != origin;
}
