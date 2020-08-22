import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/users.dart';

/// Creates circular user avatar with border around it.
class UserAvatar extends StatelessWidget {
  static const kImagePlaceholder = "assets/images/player_big.png";
  final String userName;
  final CrossAxisAlignment alignment;
  final ImageProvider imageProvider;
  final bool isActive;
  final Function onPressed;

  const UserAvatar({
    @required this.userName,
    @required this.imageProvider,
    @required this.alignment,
    this.isActive = false,
    this.onPressed,
    Key key,
  }) : super(key: key);

  UserAvatar.ofUser({
    @required User user,
    @required Function onPressed,
    bool isActive = false,
  }) : this(
          userName: user.name,
          imageProvider: _getProviderByPictureSource(user.playerData.picture),
          alignment: _getAlignmentByPosition(user.position),
          onPressed: onPressed,
          isActive: isActive,
        );

  @override
  Widget build(BuildContext context) => Column(
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
              child: _buildImage(
                imageProvider,
                const AssetImage(kImagePlaceholder),
              ),
              shape: StadiumBorder(
                side: BorderSide(
                    color: isActive
                        ? Theme.of(context).primaryColorDark
                        : Colors.white,
                    width: 5.0),
              ),
            ),
          ),
          SizedBox(height: 4.0),
          Text(userName)
        ],
      );

  static ImageProvider _getProviderByPictureSource(PictureSource source) {
    if (source is AssetPictureSource) {
      return AssetImage(source.assetName);
    }
    if (source is NetworkPictureSource) {
      return NetworkImage(source.pictureURL);
    }
    // PlaceholderImageSource
    return AssetImage(kImagePlaceholder);
  }

  static CrossAxisAlignment _getAlignmentByPosition(Position position) =>
      (position == Position.LEFT)
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end;
}

Widget _buildImage(ImageProvider target, ImageProvider placeholder) =>
    (target is AssetImage)
        ? Image(image: target)
        : FadeInImage(image: target, placeholder: placeholder);
