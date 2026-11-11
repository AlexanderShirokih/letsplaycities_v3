import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

/// Avatar of a game participant: the robot for the computer, the
/// picture of the account or the initials of the name.
Widget buildAppAvatarForUser(User user, {double size = 40}) {
  if (user is Android) return AppAvatar.computer(size: size);

  final picture = user.accountInfo.picture;
  final initials = _initials(user.name);

  if (picture is NetworkPictureSource && picture.pictureURL != null) {
    return AppAvatar.user(
      pictureUrl: picture.pictureURL,
      initials: initials,
      size: size,
    );
  }

  if (picture is AssetPictureSource) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.275),
        child: Image.asset(
          picture.assetName,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              AppAvatar.user(initials: initials, size: size),
        ),
      ),
    );
  }

  return AppAvatar.user(initials: initials, size: size);
}

/// Up to two first letters of the words of [name]
String _initials(String name) => name
    .split(RegExp(r'[ \-]'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part.characters.first.toUpperCase())
    .join();
