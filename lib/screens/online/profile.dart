import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/banlist.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/friends.dart';
import 'package:lets_play_cities/screens/online/history.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Shows user profile
class OnlineProfileView extends StatefulWidget {
  /// Profile owner id. If `null` than current authorized user will be used
  final int targetId;

  const OnlineProfileView({this.targetId, Key key}) : super(key: key);

  @override
  _OnlineProfileViewState createState() => _OnlineProfileViewState();
}

class _OnlineProfileViewState extends State<OnlineProfileView>
    with NetworkAvatarBuildingMixin {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  bool _shouldUpdate = false;

  @override
  Widget build(BuildContext context) => withData<Widget, ApiRepository>(
        context.repository<ApiRepository>(),
        (repo) => RefreshIndicator(
          onRefresh: () async => setState(() {
            _shouldUpdate = true;
          }),
          child: Stack(
            children: [
              Positioned.fill(
                child: FutureBuilder<ProfileInfo>(
                  future: repo.getProfileInfo(widget.targetId, _shouldUpdate),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      _shouldUpdate = false;
                      return _buildProfileView(context, snap.data);
                    } else if (snap.hasError) {
                      return showError(context, snap.error.toString());
                    } else {
                      return showLoadingWidget(context);
                    }
                  },
                ),
              ),
              if (_isOwner())
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, right: 24.0),
                    child: FloatingActionButton.extended(
                      onPressed: () => context
                          .repository<AccountManager>()
                          .signOut()
                          .then((_) => Navigator.of(context).pop()),
                      icon: FaIcon(FontAwesomeIcons.signOutAlt),
                      label: withLocalization(
                        context,
                        (l10n) => Text(l10n.online['sign_out']),
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      );

  Widget _buildProfileView(BuildContext context, ProfileInfo data) =>
      withLocalization(
        context,
        (l10n) => ListView(
          children: [
            ..._buildTopBlock(data, context, l10n),
            ..._buildIdBlock(data, context),
            ..._buildActionsBlock(data, context, l10n),
            ..._buildNavigationBlock(data, context, l10n),
          ],
        ),
      );

  Iterable<Widget> _buildTopBlock(
      ProfileInfo data, BuildContext context, LocalizationService l10n) sync* {
    yield Container(
      padding: EdgeInsets.all(28.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            child: InkWell(
              onTap: () {
                // TODO: Update avatar for native accounts
              },
              child:
                  buildAvatar(data.userId, data.login, data.pictureUrl, 60.0),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28.0, top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.login,
                  style: Theme.of(context).textTheme.headline6,
                  overflow: TextOverflow.fade,
                ),
                const SizedBox(height: 12.0),
                _showOnlineStatus(l10n, data),
                ..._showRole(l10n, data),
              ],
            ),
          ),
        ],
      ),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildActionsBlock(
      ProfileInfo data, BuildContext context, LocalizationService l10n) sync* {
    if (_isOwner()) return;
    yield Container(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _getFriendshipButton(data, context, l10n),
          _getFriendRequestButton(data, context, l10n),
        ],
      ),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildIdBlock(ProfileInfo data, BuildContext context) sync* {
    yield Container(
      alignment: Alignment.center,
      child: Text(
        'ID ${data.userId}',
        style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16.0),
      ),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildNavigationBlock(
      ProfileInfo data, BuildContext context, LocalizationService l10n) sync* {
    if (!_isOwner()) return;
    yield _buildNavigationButton(FaIcon(FontAwesomeIcons.userFriends),
        l10n.online['friends_tab'], () => OnlineFriendsScreen());
    yield _buildNavigationButton(FaIcon(FontAwesomeIcons.history),
        l10n.online['history_tab'], () => OnlineHistoryScreen());
    yield _buildNavigationButton(FaIcon(FontAwesomeIcons.userSlash),
        l10n.online['blacklist_tab'], () => OnlineBanlistScreen());
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Widget _buildNavigationButton(
          Widget icon, String label, Widget Function() destinationScreen) =>
      ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => RepositoryProvider.value(
              value: context.repository<ApiRepository>(),
              child: Scaffold(
                appBar: AppBar(
                  title: Text(label),
                ),
                body: destinationScreen(),
              ),
            ),
          ),
        ),
        leading: icon,
        title: Text(label),
      );

  Widget _getFriendshipButton(
          ProfileInfo data, BuildContext context, LocalizationService l10n) =>
      RaisedButton(
        shape: _createRoundedBorder(),
        onPressed: () {},
        color: Theme.of(context).primaryColor,
        child: Text(l10n.online['add_to_friend']),
      );

  Widget _getFriendRequestButton(
          ProfileInfo data, BuildContext context, LocalizationService l10n) =>
      RaisedButton(
        shape: _createRoundedBorder(),
        onPressed: () {},
        child: Text(l10n.online['invite']),
        color: Theme.of(context).primaryColor,
      );

  ShapeBorder _createRoundedBorder() => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0), side: BorderSide.none);

  Iterable<Widget> _showRole(LocalizationService l10n, ProfileInfo data) sync* {
    switch (data.role) {
      case Role.banned:
        yield const SizedBox(height: 10.0);
        yield Text(l10n.online['banned']);
        break;
      case Role.admin:
        yield const SizedBox(height: 10.0);
        yield Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.userLock),
            const SizedBox(width: 8.0),
            Text(l10n.online['admin']),
          ],
        );
        break;
      case Role.regular:
        break;
    }
  }

  Widget _showOnlineStatus(LocalizationService l10n, ProfileInfo data) {
    bool _isOnline(ProfileInfo info) =>
        DateTime.now().difference(info.lastVisitDate) < Duration(minutes: 10);

    return (_isOnline(data))
        ? Row(
            children: [
              FaIcon(
                FontAwesomeIcons.solidCircle,
                color: Colors.green,
                size: 12.0,
              ),
              const SizedBox(width: 6.0),
              Text(l10n.online['title']),
            ],
          )
        : Text(
            _getDate(l10n, data.lastVisitDate),
            style: Theme.of(context)
                .textTheme
                .bodyText2
                .copyWith(fontStyle: FontStyle.italic),
          );
  }

  String _getDate(LocalizationService l10n, DateTime date) {
    final baseFormat = l10n.online['last_online'].toString();
    final now = DateTime.now();

    switch (now.day - date.day) {
      case 0:
        return baseFormat.format([_timeFormat.format(date)]);
      case 1:
        return baseFormat.format([
          l10n.online['yesterday'].toString().format([_timeFormat.format(date)])
        ]);
      default:
        return baseFormat.format([_dateFormat.format(date)]);
    }
  }

  bool _isOwner() =>
      widget.targetId == null ||
      widget.targetId ==
          context
              .repository<AccountManager>()
              .getLastSignedInAccount()
              .credential
              .userId;
}
