/// Describes all available achievements
enum Achievement {
  write15Cities('write15Cities'),
  use3Tips('use3Tips'),
  add1Friend('add1Friend'),
  playInHardMode('playInHardMode'),
  reachScore1000Pts('reachScore1000Pts'),
  write80Cities('write80Cities'),
  loginViaSocial('loginViaSocial'),
  changeTheme('changeTheme'),
  write50CitiesInGame('write50CitiesInGame'),
  playOnline3Times('playOnline3Times'),
  use30Tips('use30Tips'),
  reachScore5000Pts('reachScore5000Pts'),
  write500Cities('write500Cities'),
  write100CitiesInGame('write100CitiesInGame'),
  reachScore25000Pts('reachScore25000Pts');

  const Achievement(this.wireName);

  /// Name of the achievement on the native game services channel.
  /// The Android side matches it against its own Achievement names,
  /// ignoring case.
  final String wireName;
}
