import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/design/app_colors.dart';
import 'package:lets_play_cities/screens/common/design/svg_path.dart';

enum AppGlyph {
  play,
  computer,
  twoPlayers,
  phone,
  wifi,
  online,
  hint,
  pause,
  resume,
  rules,
  exit,
  surrender,
  send,
  mic,
  search,
  countries,
  cities,
  profile,
  settings,
  share,
  friends,
  history,
  chat,
  back,
  close,
  more,
  check,
  trophy,
  bolt,
  globe,
  replay,
  plus,
  edit,
  trash,
  ban,
  timer,
  warning,
  gauge,
  star,
  wand,
  sound,
  moon,
  chevron,

  /// Two cards of the classic game
  classic,

  /// Dotted path to a pin of the route game
  route,

  /// «=» of a draw
  equal,

  /// Picture of the gallery
  gallery,
  camera,

  /// A person with «+»: ask to be a friend
  userPlus,

  /// A person with «−»: remove from friends
  userMinus,

  /// Arrow from the old city to the new one in an edit request
  turnRight,
}

/// One stroked (or filled) path of a glyph, in a 24x24 view box
class _Shape {
  final String d;

  /// Overrides the stroke width of the icon, for dots and inner marks
  final double? width;

  const _Shape(this.d, {this.width});
}

String _n(double v) => v.toString();

String _rect(double x, double y, double w, double h, double r) =>
    'M ${_n(x + r)} ${_n(y)} H ${_n(x + w - r)} '
    'A ${_n(r)} ${_n(r)} 0 0 1 ${_n(x + w)} ${_n(y + r)} '
    'V ${_n(y + h - r)} '
    'A ${_n(r)} ${_n(r)} 0 0 1 ${_n(x + w - r)} ${_n(y + h)} '
    'H ${_n(x + r)} '
    'A ${_n(r)} ${_n(r)} 0 0 1 ${_n(x)} ${_n(y + h - r)} '
    'V ${_n(y + r)} '
    'A ${_n(r)} ${_n(r)} 0 0 1 ${_n(x + r)} ${_n(y)} Z';

String _ellipse(double cx, double cy, double rx, double ry) =>
    'M ${_n(cx - rx)} ${_n(cy)} '
    'A ${_n(rx)} ${_n(ry)} 0 1 0 ${_n(cx + rx)} ${_n(cy)} '
    'A ${_n(rx)} ${_n(ry)} 0 1 0 ${_n(cx - rx)} ${_n(cy)} Z';

String _circle(double cx, double cy, double r) => _ellipse(cx, cy, r, r);

final _globe = [
  _Shape(_circle(12, 12, 9)),
  _Shape(_ellipse(12, 12, 3.8, 9)),
  const _Shape('M3 12h18'),
];

final _glyphs = <AppGlyph, List<_Shape>>{
  AppGlyph.play: [
    const _Shape(
      'M7 5.3v13.4a1 1 0 0 0 1.5.86l10.4-6.7a1 1 0 0 0 0-1.72L8.5 4.44A1 1 0 0 0 7 5.3z',
    ),
  ],
  AppGlyph.computer: [
    _Shape(_rect(4, 8, 16, 12, 4)),
    const _Shape('M12 8V4.6'),
    _Shape(_circle(12, 3.4, 1.2)),
    const _Shape('M9.2 13.2h.01M14.8 13.2h.01', width: 3.2),
    const _Shape('M10.2 16.6h3.6'),
  ],
  AppGlyph.twoPlayers: [
    _Shape(_rect(6, 2.5, 12, 19, 3.5)),
    const _Shape('M6 12h12'),
    const _Shape('M12 7.2h.01M12 16.8h.01', width: 3.4),
  ],
  AppGlyph.phone: [_Shape(_rect(6, 2.5, 12, 19, 3.5)), const _Shape('M11 18h2')],
  AppGlyph.wifi: [
    // Two arcs and the dot: a third arc next to the dot merges with it
    // into a blot at small sizes
    const _Shape('M3.5 10.2a12 12 0 0 1 17 0'),
    const _Shape('M7.2 14a6.8 6.8 0 0 1 9.6 0'),
    const _Shape('M12 18.6h.01', width: 3.4),
  ],
  AppGlyph.online: _globe,
  AppGlyph.globe: _globe,
  AppGlyph.hint: [
    const _Shape(
      'M12 2.8a6.6 6.6 0 0 0-3.9 11.9c.6.5.9 1.1.9 1.8v.8h6v-.8c0-.7.3-1.3.9-1.8A6.6 6.6 0 0 0 12 2.8z',
    ),
    const _Shape('M9.5 20.8h5'),
  ],
  AppGlyph.pause: [
    _Shape(_rect(6, 4.5, 4, 15, 1.4)),
    _Shape(_rect(14, 4.5, 4, 15, 1.4)),
  ],
  AppGlyph.resume: [const _Shape('M8 5v14l11-7z')],
  AppGlyph.rules: [
    const _Shape(
      'M4.5 18.3V5a2 2 0 0 1 2-2h13v15.3h-13a2 2 0 0 0-2 2 2 2 0 0 0 2 2h13',
    ),
    const _Shape('M9 7.5h6'),
  ],
  AppGlyph.exit: [
    const _Shape(
      'M10.5 3.5h6.5a2.5 2.5 0 0 1 2.5 2.5v12a2.5 2.5 0 0 1-2.5 2.5h-6.5',
    ),
    const _Shape('M14 12H3.5'),
    const _Shape('M7 8.3 3.3 12 7 15.7'),
  ],
  AppGlyph.surrender: [
    const _Shape('M5.5 21V3.5'),
    const _Shape('M5.5 4h12.2l-2.8 4.3 2.8 4.3H5.5'),
  ],
  AppGlyph.send: [const _Shape('M5 12h13'), const _Shape('M12.5 6l6 6-6 6')],
  AppGlyph.mic: [
    _Shape(_rect(8.5, 2.8, 7, 11.4, 3.5)),
    const _Shape('M5.3 11a6.7 6.7 0 0 0 13.4 0'),
    const _Shape('M12 17.7v3.5'),
  ],
  AppGlyph.search: [
    _Shape(_circle(10.8, 10.8, 6.6)),
    const _Shape('M15.8 15.8 20.5 20.5'),
  ],
  AppGlyph.countries: [const _Shape('M4 5h16l-6.2 7.6v5.6L10.2 20v-7.4z')],
  AppGlyph.cities: [
    const _Shape(
      'M9 20.5V4.8a1.3 1.3 0 0 1 1.3-1.3h3.4A1.3 1.3 0 0 1 15 4.8v15.7',
    ),
    const _Shape(
      'M9 10.2H4.8a1.3 1.3 0 0 0-1.3 1.3v9M15 13h4.2a1.3 1.3 0 0 1 1.3 1.3v6.2',
    ),
    const _Shape('M2 20.5h20'),
    const _Shape('M11.6 7.5h.8M11.6 11h.8M11.6 14.5h.8'),
  ],
  AppGlyph.profile: [
    _Shape(_circle(12, 8.3, 4.3)),
    const _Shape('M4.3 20.5c.9-4 4-6.3 7.7-6.3s6.8 2.3 7.7 6.3'),
  ],
  AppGlyph.settings: [
    const _Shape(
      'M9.89 5.11L10.33 2.55H13.67L14.11 5.11L15.38 5.64L17.51 4.14L19.86 6.49L18.36 8.62L18.89 9.89L21.45 10.33V13.67L18.89 14.11L18.36 15.38L19.86 17.51L17.51 19.86L15.38 18.36L14.11 18.89L13.67 21.45H10.33L9.89 18.89L8.62 18.36L6.49 19.86L4.14 17.51L5.64 15.38L5.11 14.11L2.55 13.67V10.33L5.11 9.89L5.64 8.62L4.14 6.49L6.49 4.14L8.62 5.64Z',
    ),
    _Shape(_circle(12, 12, 3)),
  ],
  AppGlyph.share: [
    _Shape(_circle(17.5, 5.5, 2.7)),
    _Shape(_circle(6.5, 12, 2.7)),
    _Shape(_circle(17.5, 18.5, 2.7)),
    const _Shape('M8.9 10.6l6.2-3.7M8.9 13.4l6.2 3.7'),
  ],
  AppGlyph.friends: [
    _Shape(_circle(9, 8.5, 3.6)),
    const _Shape('M2.8 20c.7-3.6 3.1-5.6 6.2-5.6s5.5 2 6.2 5.6'),
    const _Shape(
      'M15.2 4.9a3.3 3.3 0 0 1 0 6.4M17.6 14.6c2 .6 3.2 2.4 3.6 5.4',
    ),
  ],
  AppGlyph.history: [
    const _Shape('M4.3 12a8.2 8.2 0 1 0 2.4-5.8'),
    const _Shape('M4.2 3.6v3.6h3.6'),
    const _Shape('M12.5 8v4.4l3 1.9'),
  ],
  AppGlyph.chat: [
    const _Shape(
      'M5 4.5h14a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2h-7.5L7 21v-3.5H5a2 2 0 0 1-2-2v-9a2 2 0 0 1 2-2z',
    ),
    const _Shape('M7.5 9.5h9M7.5 13h5.5'),
  ],
  AppGlyph.back: [const _Shape('M19 12H5.5'), const _Shape('M11 6l-6 6 6 6')],
  AppGlyph.close: [const _Shape('M6 6l12 12M18 6 6 18')],
  AppGlyph.more: [const _Shape('M5.5 12h.01M12 12h.01M18.5 12h.01', width: 3.2)],
  AppGlyph.check: [const _Shape('M5 12.5l4.5 4.5L19 7.5')],
  AppGlyph.equal: [const _Shape('M5.5 9h13M5.5 15h13', width: 3)],
  AppGlyph.trophy: [
    const _Shape('M7 3.8h10v5.4a5 5 0 0 1-10 0z'),
    const _Shape(
      'M7 5.8H4.2v1.4A3.6 3.6 0 0 0 7.6 11M17 5.8h2.8v1.4a3.6 3.6 0 0 1-3.4 3.8',
    ),
    const _Shape('M12 14.2v3.4'),
    const _Shape('M8.6 17.6h6.8v3H8.6z'),
  ],
  AppGlyph.bolt: [const _Shape('M13.4 2.6 5 13.4h6.2l-1 8 8.6-11.2h-6.4z')],
  AppGlyph.replay: [
    const _Shape('M4.3 12a8.2 8.2 0 1 0 2.4-5.8'),
    const _Shape('M4.2 3.6v3.6h3.6'),
  ],
  AppGlyph.plus: [const _Shape('M12 5v14M5 12h14')],
  AppGlyph.edit: [
    const _Shape('M4 20l1-4L16.5 4.5a2 2 0 0 1 3 3L8 19z'),
    const _Shape('M14.5 6.5l3 3'),
  ],
  AppGlyph.trash: [
    const _Shape('M4 7h16M9.5 7V4.5h5V7'),
    const _Shape('M6 7l1 13h10l1-13'),
    const _Shape('M10 11v6M14 11v6'),
  ],
  AppGlyph.ban: [
    _Shape(_circle(12, 12, 8.6)),
    const _Shape('M5.9 5.9l12.2 12.2'),
  ],
  AppGlyph.timer: [
    _Shape(_circle(12, 13.5, 7.7)),
    const _Shape('M12 13.5V9.8'),
    const _Shape('M9.5 2.6h5'),
    const _Shape('M18.4 6.8l1.4-1.4'),
  ],
  AppGlyph.warning: [
    const _Shape('M12 3.3 2.6 19.8h18.8z'),
    const _Shape('M12 9.6v4.4'),
    const _Shape('M12 16.9h.01', width: 3.2),
  ],
  AppGlyph.gauge: [
    const _Shape('M3.5 16.5a8.5 8.5 0 0 1 17 0'),
    const _Shape('M12 16.5l4.2-5.2'),
    const _Shape('M6.4 12.2l1.2.7M12 8v1.4M17.6 12.2l-1.2.7'),
  ],
  AppGlyph.star: [
    const _Shape(
      'M12 3.2l2.6 5.5 6 .7-4.4 4.1 1.2 5.9L12 16.5l-5.4 2.9 1.2-5.9-4.4-4.1 6-.7z',
    ),
  ],
  AppGlyph.wand: [
    const _Shape('M4.5 19.5l10-10'),
    const _Shape('M12.8 7.8l3.4 3.4'),
    const _Shape(
      'M18 3.5v3M16.5 5h3M19.5 12v2.4M18.3 13.2h2.4M9.5 3.5v2.2M8.4 4.6h2.2',
    ),
  ],
  AppGlyph.sound: [
    const _Shape('M4 9.5h3.5L12 5.5v13l-4.5-4H4z'),
    const _Shape('M15.5 9.2a4 4 0 0 1 0 5.6'),
    const _Shape('M18.2 6.6a7.6 7.6 0 0 1 0 10.8'),
  ],
  AppGlyph.moon: [
    const _Shape('M19.5 14.6A8 8 0 0 1 9.4 4.5a8 8 0 1 0 10.1 10.1z'),
  ],
  AppGlyph.chevron: [const _Shape('M9.5 6l6 6-6 6')],
  AppGlyph.classic: [
    _Shape(_rect(1.5, 4.5, 9, 10.5, 2.6)),
    _Shape(_rect(13.5, 9, 9, 10.5, 2.6)),
    const _Shape('M4.6 7.9h3.4M4.6 7.9v4.4', width: 2),
    const _Shape('M15.9 16.6l2.1-4.7 2.1 4.7M16.6 15.1h2.8', width: 2),
  ],
  AppGlyph.route: [
    _Shape(_circle(5, 18.5, 2.3)),
    const _Shape('M7.6 18.5h5.4a3.5 3.5 0 0 0 3.5-3.5'),
    const _Shape(
      'M17.5 13.2s-4.2-3.7-4.2-7a4.2 4.2 0 0 1 8.4 0c0 3.3-4.2 7-4.2 7z',
    ),
    const _Shape('M17.5 6.3h.01', width: 3),
  ],
  AppGlyph.gallery: [
    _Shape(_rect(3.5, 5, 17, 14, 2.8)),
    _Shape(_circle(9, 10, 1.7)),
    const _Shape('M4.5 17l4.7-4.4 3.8 3.4 2.8-2.4 4 3.4'),
  ],
  AppGlyph.camera: [
    const _Shape(
      'M4.5 8.5h3L9 6h6l1.5 2.5h3a1 1 0 0 1 1 1V18a1 1 0 0 1-1 1h-15a1 1 0 0 1-1-1V9.5a1 1 0 0 1 1-1z',
    ),
    _Shape(_circle(12, 13.3, 3.3)),
  ],
  AppGlyph.userPlus: [..._person, const _Shape('M18.5 8v6M15.5 11h6')],
  AppGlyph.userMinus: [..._person, const _Shape('M16 11h5')],
  AppGlyph.turnRight: [
    const _Shape('M6 5v7.5h11'),
    const _Shape('M13.5 8.5l4 4-4 4'),
  ],
};

/// Head and shoulders, shifted left to leave room for a mark
final _person = [
  _Shape(_circle(9, 8.5, 3.6)),
  const _Shape('M2.8 20c.7-3.6 3.1-5.6 6.2-5.6s5.5 2 6.2 5.6'),
];

final _paths = <AppGlyph, List<(Path, _Shape)>>{};

List<(Path, _Shape)> _shapesOf(AppGlyph glyph) => _paths.putIfAbsent(glyph, () {
  return [for (final s in _glyphs[glyph]!) (parseSvgPath(s.d), s)];
});

/// Outline icon drawn from the SVG paths of the mockups (view box 24x24)
class AppIcon extends StatelessWidget {
  final AppGlyph glyph;
  final double size;
  final Color? color;
  final double strokeWidth;

  const AppIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _IconPainter(
          _shapesOf(glyph),
          color ?? AppColors.of(context).ink,
          strokeWidth,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final List<(Path, _Shape)> shapes;
  final Color color;
  final double strokeWidth;

  const _IconPainter(this.shapes, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);

    // A translucent color would add up where the strokes of two shapes
    // overlap, so the icon is drawn opaque and faded as a whole.
    final translucent = color.a < 1 && shapes.length > 1;
    final stroke = translucent ? color.withValues(alpha: 1) : color;
    if (translucent) {
      canvas.saveLayer(
        const Rect.fromLTWH(-2, -2, 28, 28),
        Paint()..color = Color.fromRGBO(0, 0, 0, color.a),
      );
    }

    for (final (path, shape) in shapes) {
      final paint = Paint()
        ..color = stroke
        ..isAntiAlias = true;

      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = shape.width ?? strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, paint);
    }

    if (translucent) canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.shapes != shapes ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}
