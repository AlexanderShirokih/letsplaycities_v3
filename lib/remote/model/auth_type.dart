/// Describes account types
enum AuthType {
  native('nv', 'Native'),
  google('gl', 'Google'),
  vkontakte('vk', 'Vkontakte'),
  odnoklassniki('ok', 'Odnoklassniki'),
  facebook('fb', 'Facebook');

  const AuthType(this.shortName, this.fullName);

  /// Name used on the native social login channel ('authType', 'networkType')
  final String shortName;

  /// Name used by the game server and the REST API ('authType')
  final String fullName;

  /// Returns the type named [s] by its [shortName].
  /// Throws a [String] when there is no such type.
  static AuthType fromShortString(String s) {
    for (final type in values) {
      if (type.shortName == s) {
        return type;
      }
    }
    throw 'Unknown value "$s"!';
  }

  /// Returns the type named [s] by its [fullName].
  /// Throws a [String] when there is no such type.
  static AuthType fromString(String s) {
    for (final type in values) {
      if (type.fullName == s) {
        return type;
      }
    }
    throw 'Unknown value "$s"!';
  }
}
