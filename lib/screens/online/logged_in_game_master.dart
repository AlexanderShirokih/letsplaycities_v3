import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'game_waiting_room_screen.dart';

/// A screen used to prepare user for online game and navigate between
/// online-related routes when user is logged in
class LoggedInOnlineGameMasterScreen extends StatefulWidget {
  const LoggedInOnlineGameMasterScreen({super.key});

  @override
  State<LoggedInOnlineGameMasterScreen> createState() =>
      _LoggedInOnlineGameMasterScreenState();
}

class _LoggedInOnlineGameMasterScreenState
    extends State<LoggedInOnlineGameMasterScreen> {
  int _tabId = 0;

  final _tabs = <Widget>[GameWaitingRoomScreen(), OnlineProfileView()];

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return RepositoryProvider<ApiRepository>.value(
      value: GetIt.instance.get<ApiRepositoryFactory>().forCredential(
        context.watch<RemoteAccount>().credential,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text([t.online.title, t.online.profileTab][_tabId]),
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
                label: t.online.gameTab,
                backgroundColor: color,
              ),
              BottomNavigationBarItem(
                icon: FaIcon(FontAwesomeIcons.circleUser),
                label: t.online.profileTab,
                backgroundColor: color,
              ),
            ],
            onTap: (tabId) => setState(() {
              _tabId = tabId;
            }),
          ),
        ),
      ),
    );
  }
}
