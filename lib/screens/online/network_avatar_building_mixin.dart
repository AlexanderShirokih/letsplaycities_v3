import 'package:flutter/material.dart';

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
  /// default text avatar from [login] initials
  Widget buildAvatar(
          int userId, String login, String pictureUrl, double radius) =>
      pictureUrl == null
          ? _buildTextAvatar(userId, login, 46.0)
          : CircleAvatar(
              radius: 46.0,
              key: ObjectKey(userId),
              backgroundImage: NetworkImage(pictureUrl),
              backgroundColor: Colors.transparent,
            );

  Widget _buildTextAvatar(int userId, String login, double radius) =>
      CircleAvatar(
        radius: 46.0,
        key: ObjectKey(userId),
        child: Text(
          _getInitials(login),
          style: TextStyle(fontSize: 24.0),
        ),
        backgroundColor: _colors[userId % _colors.length],
      );

  String _getInitials(String login) => login
      .split(RegExp('[ \\-]'))
      .map((e) => e.characters.first.toUpperCase())
      .reduce((value, element) => value + element);
}
