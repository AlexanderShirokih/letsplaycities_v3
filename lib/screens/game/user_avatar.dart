import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';

/// Creates circular user avatar with border around it.
class UserAvatar extends StatelessWidget with NetworkAvatarBuildingMixin {
  final User _user;
  final CrossAxisAlignment alignment;

  UserAvatar({required User user, Key? key})
      : alignment = _getAlignmentByPosition(user.position),
        _user = user,
        super(key: key);

  @override
  Widget build(BuildContext rootContext) => StreamBuilder<OnUserSwitchedEvent>(
        stream:
            rootContext.watch<GameServiceEventsRepository>().getUserSwitches(),
        builder: (context, snapshot) => Container(
          width: 80.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: alignment,
            children: [
              _AvatarBorderAnimator(
                user: _user,
                isActive:
                    snapshot.hasData && snapshot.requireData.nextUser == _user,
                borderColor: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 4.0),
              Text(
                _user.info,
                overflow: TextOverflow.fade,
              ),
            ],
          ),
        ),
      );

  static CrossAxisAlignment _getAlignmentByPosition(Position position) =>
      (position == Position.LEFT)
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end;
}

class _AvatarBorderAnimator extends StatefulWidget {
  final User user;
  final bool isActive;
  final Color borderColor;

  const _AvatarBorderAnimator({
    Key? key,
    required this.user,
    required this.isActive,
    required this.borderColor,
  }) : super(key: key);

  @override
  __AvatarBorderAnimatorState createState() => __AvatarBorderAnimatorState();
}

class __AvatarBorderAnimatorState extends State<_AvatarBorderAnimator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    animation = ColorTween(
      begin: widget.borderColor,
      end: Colors.white,
    ).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: buildAvatarForUser(widget.user, 35.0),
      decoration: ShapeDecoration(
        shape: StadiumBorder(
          side: BorderSide(
            color: widget.isActive ? animation.value! : Colors.white,
            width: 5.0,
          ),
        ),
      ),
    );
  }
}

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
      backgroundImage:
          _getImageProviderByPictureSource(user.accountInfo.picture),
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
