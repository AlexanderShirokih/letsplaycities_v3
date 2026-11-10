import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Three pages with the rules, then starts [GameScreen], or goes back to the
/// running game when it is a [replay] of the rules.
class FirstTimeOnBoardingScreen extends StatefulWidget {
  final GameConfig gameConfig;
  final bool replay;

  const FirstTimeOnBoardingScreen({
    super.key,
    required this.gameConfig,
    this.replay = false,
  });

  @override
  State<FirstTimeOnBoardingScreen> createState() =>
      _FirstTimeOnBoardingScreenState();
}

class _FirstTimeOnBoardingScreenState extends State<FirstTimeOnBoardingScreen> {
  static const _total = 3;

  final _controller = PageController();
  var _page = 0;

  /// The screen is leaving: a tap during the route animation must not pop
  /// the game under it.
  bool _leaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    if (_leaving) return;
    _leaving = true;

    if (widget.replay) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(widget.gameConfig)),
      );
    }
  }

  void _next() {
    if (_page == _total - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final s = t.firstTimeScreen;
    final last = _page == _total - 1;

    final pages = [
      _RulesPage(
        art: _WordLadder(from: s.step1From, to: s.step1To),
        title: s.step1Title,
        text: s.step1Text,
      ),
      _RulesPage(
        art: _WordLadder(from: s.step2From, to: s.step2To),
        title: s.step2Title,
        text: s.step2Text,
      ),
      _RulesPage(
        art: D2TileArt(glyph: D2Glyph.trophy, tileColor: c.yellow),
        title: s.step3Title,
        text: s.step3Text,
      ),
    ];

    // Material gives the text its theme instead of the debug style with
    // yellow underlines
    return Material(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: c.inkSoft,
                    textStyle: D2Text.body.copyWith(fontSize: 15),
                  ),
                  child: Text(s.skip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  Semantics(
                    liveRegion: true,
                    label: s.stepOf(step: _page + 1, total: _total),
                    excludeSemantics: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < _total; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: i == _page ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _page ? c.violet : c.edge,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  D2Button(
                    label: last ? t.home.play : s.next,
                    icon: last ? D2Glyph.play : null,
                    size: D2ButtonSize.large,
                    expand: true,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One page: art, title and text in the middle of the free space
class _RulesPage extends StatelessWidget {
  final Widget art;
  final String title;
  final String text;

  const _RulesPage({
    required this.art,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 150,
                    child: Center(child: FittedBox(child: art)),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: D2Text.display.copyWith(fontSize: 24, color: c.ink),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: D2Text.bodyRegular.copyWith(
                      fontSize: 16,
                      height: 1.4,
                      color: c.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two words in letter tiles: the second one starts under the move letter of
/// the first one, the letters after it do not count.
class _WordLadder extends StatelessWidget {
  static const _tileWidth = 36.0;
  static const _gap = 4.0;

  final String from;
  final String to;

  const _WordLadder({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final upperFrom = from.toUpperCase();
    final upperTo = to.toUpperCase();
    final move = indexOfLastSuitableChar(from.toLowerCase());
    final offset = move * (_tileWidth + _gap);
    final width = [
      upperFrom.length * (_tileWidth + _gap),
      offset + upperTo.length * (_tileWidth + _gap),
    ].reduce((a, b) => a > b ? a : b);

    Widget tile(String letter, D2TileColor color) => Padding(
      padding: const EdgeInsets.only(right: _gap),
      child: D2LetterTile(
        letter,
        size: _tileWidth,
        height: 44,
        color: color,
        semanticLabel: letter,
      ),
    );

    return Semantics(
      image: true,
      label: '$from → $to',
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < upperFrom.length; i++)
                  tile(
                    upperFrom[i],
                    i == move
                        ? D2TileColor.orange
                        : i > move
                        ? D2TileColor.ghost
                        : D2TileColor.white,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Padding(
              padding: EdgeInsets.only(left: offset),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < upperTo.length; i++)
                    tile(
                      upperTo[i],
                      i == 0 ? D2TileColor.orange : D2TileColor.white,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
