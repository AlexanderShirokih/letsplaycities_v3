import 'dart:ui';

/// Parses SVG path data [d] into a [Path].
///
/// Supports M, L, H, V, C, S, Q, T, A and Z, both absolute and relative.
Path parseSvgPath(String d) {
  final s = _Scanner(d);
  final path = Path();
  var x = 0.0, y = 0.0;
  var startX = 0.0, startY = 0.0;

  // Last control point, used by the smooth commands.
  var ctrlX = 0.0, ctrlY = 0.0;
  var prev = '';
  var cmd = '';

  while (true) {
    s.skipSeparators();
    if (s.atEnd) break;

    if (s.isCommand) {
      cmd = s.readCommand();
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        x = startX;
        y = startY;
        prev = 'Z';
        continue;
      }
    } else if (cmd.isEmpty) {
      throw FormatException('Path data must start with a command', d);
    }

    final rel = cmd == cmd.toLowerCase();
    final dx = rel ? x : 0.0;
    final dy = rel ? y : 0.0;

    switch (cmd.toUpperCase()) {
      case 'M':
        x = s.number() + dx;
        y = s.number() + dy;
        startX = x;
        startY = y;
        path.moveTo(x, y);
        // Further coordinate pairs are implicit line-tos.
        cmd = rel ? 'l' : 'L';
        prev = 'M';
      case 'L':
        x = s.number() + dx;
        y = s.number() + dy;
        path.lineTo(x, y);
        prev = 'L';
      case 'H':
        x = s.number() + dx;
        path.lineTo(x, y);
        prev = 'H';
      case 'V':
        y = s.number() + dy;
        path.lineTo(x, y);
        prev = 'V';
      case 'C':
        final x1 = s.number() + dx, y1 = s.number() + dy;
        final x2 = s.number() + dx, y2 = s.number() + dy;
        x = s.number() + dx;
        y = s.number() + dy;
        path.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
        prev = 'C';
      case 'S':
        final smooth = prev == 'C' || prev == 'S';
        final x1 = smooth ? 2 * x - ctrlX : x;
        final y1 = smooth ? 2 * y - ctrlY : y;
        final x2 = s.number() + dx, y2 = s.number() + dy;
        x = s.number() + dx;
        y = s.number() + dy;
        path.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
        prev = 'S';
      case 'Q':
        final x1 = s.number() + dx, y1 = s.number() + dy;
        x = s.number() + dx;
        y = s.number() + dy;
        path.quadraticBezierTo(x1, y1, x, y);
        ctrlX = x1;
        ctrlY = y1;
        prev = 'Q';
      case 'T':
        final smooth = prev == 'Q' || prev == 'T';
        final x1 = smooth ? 2 * x - ctrlX : x;
        final y1 = smooth ? 2 * y - ctrlY : y;
        x = s.number() + dx;
        y = s.number() + dy;
        path.quadraticBezierTo(x1, y1, x, y);
        ctrlX = x1;
        ctrlY = y1;
        prev = 'T';
      case 'A':
        final rx = s.number(), ry = s.number();
        final rotation = s.number();
        final large = s.flag();
        final sweep = s.flag();
        x = s.number() + dx;
        y = s.number() + dy;
        if (rx == 0 || ry == 0) {
          path.lineTo(x, y);
        } else {
          path.arcToPoint(
            Offset(x, y),
            radius: Radius.elliptical(rx.abs(), ry.abs()),
            rotation: rotation,
            largeArc: large,
            clockwise: sweep,
          );
        }
        prev = 'A';
      default:
        throw FormatException('Unsupported path command $cmd', d);
    }
  }

  return path;
}

class _Scanner {
  final String _s;
  var _i = 0;

  _Scanner(this._s);

  bool get atEnd => _i >= _s.length;

  bool get isCommand => 'MmLlHhVvCcSsQqTtAaZz'.contains(_s[_i]);

  String readCommand() => _s[_i++];

  void skipSeparators() {
    while (_i < _s.length) {
      final c = _s.codeUnitAt(_i);
      if (c == 0x20 || c == 0x2C || c == 0x0A || c == 0x09 || c == 0x0D) {
        _i++;
      } else {
        break;
      }
    }
  }

  /// Reads an arc flag, which may be glued to the next number ("011 1").
  bool flag() {
    skipSeparators();
    final c = _s[_i++];
    if (c != '0' && c != '1') {
      throw FormatException('Invalid arc flag', _s, _i - 1);
    }

    return c == '1';
  }

  double number() {
    skipSeparators();
    final start = _i;
    if (_i < _s.length && (_s[_i] == '-' || _s[_i] == '+')) _i++;

    var dot = false;
    while (_i < _s.length) {
      final c = _s[_i];
      if (c == '.') {
        if (dot) break;
        dot = true;
        _i++;
      } else if (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
        _i++;
      } else {
        break;
      }
    }

    if ((_i < _s.length) && (_s[_i] == 'e' || _s[_i] == 'E')) {
      _i++;
      if (_i < _s.length && (_s[_i] == '-' || _s[_i] == '+')) _i++;
      while (_i < _s.length &&
          _s.codeUnitAt(_i) >= 0x30 &&
          _s.codeUnitAt(_i) <= 0x39) {
        _i++;
      }
    }

    final v = double.tryParse(_s.substring(start, _i));
    if (v == null) throw FormatException('Number expected', _s, start);

    return v;
  }
}
