import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';

/// Creates circular user avatar with border around it.
class UserAvatar extends StatelessWidget {
  final User _user;
  final CrossAxisAlignment alignment;
  final PictureSource source;
  final Function onPressed;

  UserAvatar({
    @required User user,
    @required this.onPressed,
    Key key,
  })  : source = user.accountInfo.picture,
        alignment = _getAlignmentByPosition(user.position),
        _user = user,
        super(key: key);

  @override
  Widget build(BuildContext rootContext) => StreamBuilder<Map<User, bool>>(
        stream: rootContext
            .repository<GameServiceEventsRepository>()
            .getUserSwitches(),
        builder: (context, snapshot) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignment,
          children: [
            Container(
              width: 70.0,
              height: 70.0,
              child: FlatButton(
                onPressed: onPressed,
                color: Colors.white,
                padding: EdgeInsets.zero,
                child: buildUserAvatar(source),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: snapshot.hasData &&
                            snapshot.data.entries
                                .any((u) => u.value && u.key == _user)
                        ? Theme.of(context).primaryColorDark
                        : Colors.white,
                    width: 5.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              snapshot.hasData
                  ? snapshot.data.keys.singleWhere((user) => user == _user).info
                  : '--',
            ),
          ],
        ),
      );

  static CrossAxisAlignment _getAlignmentByPosition(Position position) =>
      (position == Position.LEFT)
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end;
}

/// Creates users avatar Image depending of picture type
Widget buildUserAvatar(PictureSource pictureSource) => _buildImage(
    _getImageProviderByPictureSource(pictureSource),
    const AssetImage(_kImagePlaceholder));

const _kImagePlaceholder = 'assets/images/player_big.png';

Widget _buildImage(ImageProvider target, ImageProvider placeholder) =>
    (target is AssetImage)
        ? Image(image: target)
        : FadeInImage(image: target, placeholder: placeholder);

ImageProvider _getImageProviderByPictureSource(PictureSource source) {
  if (source is AssetPictureSource) {
    return AssetImage(source.assetName);
  }
  if (source is NetworkPictureSource) {
    return NetworkImage(source.pictureURL);
  }

  // PlaceholderImageSource
  return AssetImage(_kImagePlaceholder);
}
