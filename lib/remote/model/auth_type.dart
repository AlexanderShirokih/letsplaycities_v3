/// Describes account types
enum AuthType {
  native('nv', 'Native', 'native'),
  google('gl', 'Google', 'google'),
  vkontakte('vk', 'Vkontakte', 'vk'),
  odnoklassniki('ok', 'Odnoklassniki', 'ok'),
  facebook('fb', 'Facebook', 'fb');

  const AuthType(this.shortName, this.fullName, this.provider);

  /// Name used on the native social login channel ('authType', 'networkType')
  final String shortName;

  /// Name used by the LAN game server ('authType')
  final String fullName;

  /// Name used by the REST API v1 (`provider`)
  final String provider;

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
