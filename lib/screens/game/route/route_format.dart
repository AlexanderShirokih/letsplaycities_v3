import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/users.dart';

import '../../common/d2/d2_colors.dart';

/// Non-breaking space: between the thousands and before «км»
const kmSpace = '\u00A0';

/// [km] with the thousands split by [kmSpace]: «12 480»
String formatKm(int km) {
  final digits = km.abs().toString();
  final out = StringBuffer(km < 0 ? '-' : '');

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(kmSpace);
    out.write(digits[i]);
  }

  return out.toString();
}

/// The color of [user] on the route: violet for the first player, orange for
/// the second
Color routeColorOf(User user, D2Colors c) =>
    user.position == Position.left ? c.violet : c.orange;

/// The color of the km text of [user]: the orange of the second player is
/// too light for text, so it takes the letter color
Color routeKmColorOf(User user, D2Colors c) =>
    user.position == Position.left ? c.violet : c.letter;
