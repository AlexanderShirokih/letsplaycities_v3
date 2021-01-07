import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'game_waiting_room_screen.dart';

/// A screen used to prepare user for online game and navigate between
/// online-related routes when user is logged in
class LoggedInOnlineGameMasterScreen extends StatefulWidget {
  @override
  _LoggedInOnlineGameMasterScreenState createState() =>
      _LoggedInOnlineGameMasterScreenState();
}

class _LoggedInOnlineGameMasterScreenState
    extends State<LoggedInOnlineGameMasterScreen> {
  int _tabId = 0;

  final _tabs = <Widget>[
    GameWaitingRoomScreen(),
    OnlineProfileView(),
  ];

  @override
  Widget build(BuildContext context) => buildWithLocalization(
        context,
        (l10n) => RepositoryProvider<ApiRepository>.value(
          value: context.watch<RemoteAccount>().getApiRepository(),
          child: Scaffold(
            appBar: AppBar(
              title: Text([
                l10n.online['title'],
                l10n.online['profile_tab'],
              ][_tabId]),
            ),
            body: _tabs[_tabId],
            bottomNavigationBar: withData<Widget, Color>(
              Theme.of(context).primaryColor,
              (color) => BottomNavigationBar(
                currentIndex: _tabId,
                elevation: 5.0,
                items: [
                  BottomNavigationBarItem(
                    icon: FaIcon(FontAwesomeIcons.dice),
                    label: l10n.online['game_tab'],
                    backgroundColor: color,
                  ),
                  BottomNavigationBarItem(
                    icon: FaIcon(FontAwesomeIcons.userCircle),
                    label: l10n.online['profile_tab'],
                    backgroundColor: color,
                  ),
                ],
                onTap: (tabId) => setState(() {
                  _tabId = tabId;
                }),
              ),
            ),
          ),
        ),
      );
}
