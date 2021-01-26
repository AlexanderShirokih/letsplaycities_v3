import 'package:flutter/foundation.dart';

/// Describes account types
enum AuthType { Native, Google, Vkontakte, Odnoklassniki, Facebook }

extension AuthTypeExtension on AuthType {
  String get name {
    switch (this) {
      case AuthType.Native:
        return 'nv';
      case AuthType.Google:
        return 'gl';
      case AuthType.Vkontakte:
        return 'vk';
      case AuthType.Odnoklassniki:
        return 'ok';
      case AuthType.Facebook:
        return 'fb';
      default:
        throw Exception('Unknown AuthType value: $this');
    }
  }

  String get fullName => describeEnum(this);

  static AuthType fromShortString(String s) {
    for (final type in AuthType.values) {
      if (type.name == s) {
        return type;
      }
    }
    throw 'Unknown value "$s"!';
  }

  static AuthType fromString(String s) {
    for (final type in AuthType.values) {
      if (type.fullName == s) {
        return type;
      }
    }
    throw 'Unknown value "$s"!';
  }
}
