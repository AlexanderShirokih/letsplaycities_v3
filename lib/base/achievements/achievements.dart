import 'package:flutter/foundation.dart';

/// Describes all available achievements
enum Achievement {
  write15Cities,
  use3Tips,
  add1Friend,
  playInHardMode,
  reachScore1000Pts,
  write80Cities,
  loginViaSocial,
  changeTheme,
  write50CitiesInGame,
  playOnline3Times,
  use30Tips,
  reachScore5000Pts,
  write500Cities,
  write100CitiesInGame,
  reachScore25000Pts,
}

extension AchievementExtension on Achievement {
  String get name => describeEnum(this);
}
