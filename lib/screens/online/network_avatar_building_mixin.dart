import 'package:flutter/material.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Contains utility functions to build avatars from the network
mixin NetworkAvatarBuildingMixin {
  static const _colors = [
    Colors.red,
    Colors.green,
    Colors.deepPurple,
    Colors.blue,
    Colors.yellow,
    Colors.cyan,
    Colors.lime,
  ];

  /// Creates [CircleAvatar] from [pictureUrl] if it's not `null` or builds
  /// default text avatar from [profile.login] initials
  Widget buildAvatar(BaseProfileInfo profile, [double radius = 46.0]) =>
      profile.pictureUrl == null
          ? _buildTextAvatar(profile, radius)
          : CircleAvatar(
              radius: radius,
              key: ObjectKey(profile),
              backgroundImage: NetworkImage(profile.pictureUrl!),
              backgroundColor: Colors.transparent,
            );

  Widget _buildTextAvatar(BaseProfileInfo profile, double radius) =>
      CircleAvatar(
        radius: radius,
        key: ObjectKey(profile),
        backgroundColor: _colors[profile.userId % _colors.length],
        child: Text(
          _getInitials(profile.login),
          style: TextStyle(fontSize: 24.0),
        ),
      );

  String _getInitials(String login) => login
      .split(RegExp('[ \\-]'))
      .map((e) => e.characters.first.toUpperCase())
      .reduce((value, element) => value + element);
}
