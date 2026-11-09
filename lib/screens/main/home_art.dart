import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';

/// The cards of the home screen
enum HomeArt { computer, twoPlayers, wifi, online }

/// Background of a home card: a chain of cities drifting in rows and an
/// illustration, drawn by the SVG of the D2-Home artboard
class HomeCardArt extends StatefulWidget {
  final HomeArt art;

  const HomeCardArt(this.art, {super.key});

  @override
  State<HomeCardArt> createState() => _HomeCardArtState();
}

class _HomeCardArtState extends State<HomeCardArt>
    with SingleTickerProviderStateMixin {
  /// Seconds since the drift started
  final _time = ValueNotifier<double>(0);

  /// Drift in pixels per second, picked anew for each card so they move
  /// out of step
  final _speed = 3.5 + math.Random().nextDouble() * 3.5;

  late final _ticker = createTicker(
    (elapsed) => _time.value = elapsed.inMicroseconds / 1e6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final still = MediaQuery.disableAnimationsOf(context);

    if (still && _ticker.isActive) {
      _ticker.stop();
      _time.value = 0;
    } else if (!still && !_ticker.isActive) {
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
    final colors = D2Colors.of(context);

    return ExcludeSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _CityDriftPainter(widget.art, colors, _time, _speed),
            ),
          ),
          CustomPaint(painter: _HomeArtPainter(widget.art, colors)),
        ],
      ),
    );
  }
}

/// A closed chain of cities: each one starts with the letter the previous
/// one ends on, and the last one leads back to the first
const _cities = [
  'Амстердам',
  'Мадрид',
  'Дублин',
  'Нью-Йорк',
  'Каир',
  'Рим',
  'Мюнхен',
  'Найроби',
  'Измир',
  'Рио-де-Жанейро',
  'Осло',
  'Оттава',
  'Афины',
  'Неаполь',
  'Лиссабон',
  'Новосибирск',
  'Киото',
  'Одесса',
  'Анкара',
  'Астана',
  'Алматы',
  'Тбилиси',
  'Иокогама',
  'Аккра',
];

/// The letter pattern of the artboard spelling the city chain, sliding to
/// the left
class _CityDriftPainter extends CustomPainter {
  final HomeArt art;
  final D2Colors c;
  final ValueListenable<double> time;

  /// Pixels per second
  final double speed;

  _CityDriftPainter(this.art, this.c, this.time, this.speed)
    : super(repaint: time);

  static const _step = 34.0;

  /// The chain letter by letter with an empty cell between cities
  static final _cells = '${_cities.join(' ')} '.toUpperCase();

  final _letters = <String, TextPainter>{};

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    final opacity = switch (art) {
      HomeArt.computer || HomeArt.twoPlayers => 0.08,
      HomeArt.wifi || HomeArt.online => 0.07,
    };
    final style = D2Text.display.copyWith(
      fontSize: 20,
      color: c.shadow.withValues(alpha: opacity),
    );

    final travelled = speed * time.value;
    final passed = (travelled / _step).floor();
    final shift = travelled - passed * _step;

    // Each card and each row start somewhere else in the chain
    final start = art.index * _cells.length ~/ HomeArt.values.length;

    for (var row = 0; 14 + _step * row < size.height + 20; row++) {
      final baseline = 14 + _step * row;
      final first = start + row * 29 + passed;
      var j = 0;

      for (
        var x = (row.isEven ? -6.0 : 11.0) - shift;
        x < size.width + 10;
        x += _step, j++
      ) {
        final letter = _cells[(first + j) % _cells.length];

        if (letter != ' ') _paintLetter(canvas, letter, style, x, baseline);
      }
    }
  }

  void _paintLetter(
    Canvas canvas,
    String letter,
    TextStyle style,
    double x,
    double baseline,
  ) {
    final painter = _letters.putIfAbsent(
      letter,
      () => TextPainter(
        text: TextSpan(text: letter, style: style),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(),
    );
    final ascent = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(canvas, Offset(x, baseline - ascent));
  }

  @override
  bool shouldRepaint(_CityDriftPainter old) =>
      old.art != art || old.c != c || old.time != time || old.speed != speed;
}

/// The illustration of a home card
class _HomeArtPainter extends CustomPainter {
  final HomeArt art;
  final D2Colors c;

  _HomeArtPainter(this.art, this.c);

  final _letters = <String, TextPainter>{};

  Color get _ink => c.shadow;

  /// Width of the illustration in the artboard
  double get _artWidth => art == HomeArt.computer ? 328 : 158;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    // The illustrations keep their artboard place on a wider card: at the
    // right edge, or in the middle for the tall card
    final extra = size.width - _artWidth;
    final dx = art == HomeArt.twoPlayers ? extra / 2 : extra;
    canvas.translate(dx, 0);

    switch (art) {
      case HomeArt.computer:
        _computer(canvas);
      case HomeArt.twoPlayers:
        _twoPlayers(canvas);
      case HomeArt.wifi:
        _wifi(canvas);
      case HomeArt.online:
        _online(canvas);
    }
  }

  void _computer(Canvas canvas) {
    _rotated(canvas, 8, 262, 92, () {
      _box(canvas, const Rect.fromLTWH(214, 46, 96, 88), 24, c.sky, 6);
      _box(canvas, const Rect.fromLTWH(230, 68, 64, 46), 14, Colors.white, 0);
      canvas.drawCircle(const Offset(250, 90), 5, _fill);
      canvas.drawCircle(const Offset(274, 90), 5, _fill);
      canvas.drawPath(parseSvgPath('M262 46V32'), _stroke);
      canvas.drawCircle(const Offset(262, 29), 5, Paint()..color = c.yellow);
      canvas.drawCircle(const Offset(262, 29), 5, _stroke);
    });

    _rotated(canvas, -12, 284, 161, () {
      _tile(canvas, const Rect.fromLTWH(264, 140, 40, 42), 10, Colors.white);
      _centered(canvas, 'М', 21, 284, 168.56);
    });

    _rotated(canvas, 10, 167, 42, () {
      _tile(canvas, const Rect.fromLTWH(150, 24, 34, 36), 8, c.yellow);
      _centered(canvas, 'А', 18, 167, 48.48);
    });
  }

  void _twoPlayers(Canvas canvas) {
    void phone(double x, double y, Color fill, String letter) {
      _box(canvas, Rect.fromLTWH(x, y, 58, 96), 12, fill, 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + 21, y + 6, 16, 3),
          const Radius.circular(1.5),
        ),
        _fill,
      );
      _tile(canvas, Rect.fromLTWH(x + 14, y + 32, 30, 30), 8, c.orange);
      _centered(canvas, letter, 16, x + 29, y + 52.76);
    }

    _rotated(canvas, -12, 47, 76, () => phone(18, 28, Colors.white, 'К'));
    _rotated(canvas, 10, 111, 118, () => phone(82, 70, c.yellow, 'А'));

    _dashed(canvas, parseSvgPath('M50 140 C 60 170, 110 176, 120 150'), 2, 6);
    canvas.drawPath(parseSvgPath('M113 150 L121 148 L123 156'), _stroke);
  }

  void _wifi(Canvas canvas) {
    for (final x in [52.0, 114.0]) {
      _box(canvas, Rect.fromLTWH(x, 14, 30, 50), 8, Colors.white, 3);
      canvas.drawPath(parseSvgPath('M${x + 11} 56h8'), _stroke);
    }

    canvas.drawPath(
      parseSvgPath('M89 34a12 12 0 0 1 18 0M93 41a6 6 0 0 1 10 0'),
      _stroke,
    );
    canvas.drawCircle(const Offset(98, 47), 2.5, _fill);
  }

  void _online(Canvas canvas) {
    canvas.drawCircle(const Offset(117, 44), 27, _fill);
    canvas.drawCircle(const Offset(117, 41), 27, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(117, 41), 27, _stroke);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(117, 41), width: 22, height: 54),
      _stroke,
    );
    canvas.drawPath(parseSvgPath('M90 41h54'), _stroke);

    _rotated(canvas, -10, 66, 52, () {
      _box(canvas, const Rect.fromLTWH(52, 38, 28, 30), 8, c.orange, 3);
      _centered(canvas, 'А', 15, 66, 58.5);
    });
  }

  Paint get _fill => Paint()..color = _ink;

  Paint get _stroke => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _ink;

  /// A letter tile: a hard shadow 4 px below, then the outlined [rect]
  void _tile(Canvas canvas, Rect rect, double radius, Color fill) =>
      _box(canvas, rect, radius, fill, 4);

  /// Outlined [rect] with a hard shadow [shadow] px below it
  void _box(
    Canvas canvas,
    Rect rect,
    double radius,
    Color fill,
    double shadow,
  ) {
    RRect rrect(double dy) => RRect.fromRectAndRadius(
      rect.shift(Offset(0, dy)),
      Radius.circular(radius),
    );

    if (shadow > 0) canvas.drawRRect(rrect(shadow), _fill);
    canvas.drawRRect(rrect(0), Paint()..color = fill);
    canvas.drawRRect(rrect(0), _stroke);
  }

  void _rotated(
    Canvas canvas,
    double degrees,
    double cx,
    double cy,
    VoidCallback draw,
  ) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.translate(-cx, -cy);
    draw();
    canvas.restore();
  }

  void _dashed(Canvas canvas, Path path, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      for (var pos = 0.0; pos < metric.length; pos += dash + gap) {
        canvas.drawPath(metric.extractPath(pos, pos + dash), _stroke);
      }
    }
  }

  /// [letter] centered on [x] with its baseline at [baseline]
  void _centered(
    Canvas canvas,
    String letter,
    double fontSize,
    double x,
    double baseline,
  ) {
    final style = D2Text.display.copyWith(fontSize: fontSize, color: _ink);
    final painter = _painter(letter, style);
    _text(canvas, letter, style, x - painter.width / 2, baseline);
  }

  /// [letter] starting at [x] with its baseline at [baseline]
  void _text(
    Canvas canvas,
    String letter,
    TextStyle style,
    double x,
    double baseline,
  ) {
    final painter = _painter(letter, style);
    final ascent = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.paint(canvas, Offset(x, baseline - ascent));
  }

  TextPainter _painter(String letter, TextStyle style) => _letters.putIfAbsent(
    '$letter ${style.fontSize} ${style.color}',
    () => TextPainter(
      text: TextSpan(text: letter, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(),
  );

  @override
  bool shouldRepaint(_HomeArtPainter old) => old.art != art || old.c != c;
}
