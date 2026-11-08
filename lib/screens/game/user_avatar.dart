import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';

/// D2 avatar of a game participant: the robot for the computer, the
/// picture of the account or the initials of the name.
Widget buildD2AvatarForUser(User user, {double size = 40}) {
  if (user is Android) return D2Avatar.computer(size: size);

  final picture = user.accountInfo.picture;
  final initials = _initials(user.name);

  if (picture is NetworkPictureSource && picture.pictureURL != null) {
    return D2Avatar.user(
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
              D2Avatar.user(initials: initials, size: size),
        ),
      ),
    );
  }

  return D2Avatar.user(initials: initials, size: size);
}

/// Up to two first letters of the words of [name]
String _initials(String name) => name
    .split(RegExp(r'[ \-]'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part.characters.first.toUpperCase())
    .join();

class _NetworkAvatarBuilder with NetworkAvatarBuildingMixin {}

Widget buildAvatarForUser(User user, double radius) {
  final builder = _NetworkAvatarBuilder();
  final accountInfo = user.accountInfo;
  if (accountInfo is RemoteAccount) {
    return builder.buildAvatar(accountInfo.baseProfileInfo, radius);
  } else if (accountInfo is AdvancedAccountInfo) {
    return builder.buildAvatar(accountInfo.profileInfo, radius);
  } else {
    return CircleAvatar(
      radius: radius,
      backgroundImage: _getImageProviderByPictureSource(
        user.accountInfo.picture,
      ),
    );
  }
}

const _kImagePlaceholder = 'assets/images/player_big.png';

ImageProvider _getImageProviderByPictureSource(PictureSource source) {
  if (source is AssetPictureSource) {
    return AssetImage(source.assetName);
  }

  if (source is NetworkPictureSource && source.pictureURL != null) {
    return NetworkImage(source.pictureURL!);
  }

  // PlaceholderImageSource
  return AssetImage(_kImagePlaceholder);
}
