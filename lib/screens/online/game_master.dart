import 'package:flutter/material.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/screens/common/authentication_view.dart';
import 'package:lets_play_cities/screens/online/online_home_screen.dart';

/// Signs the user in if needed and shows [OnlineHomeScreen]
class OnlineGameMasterScreen extends StatelessWidget {
  /// Invited as soon as «Онлайн» opens
  final LpsUser? invite;

  const OnlineGameMasterScreen({super.key, this.invite});

  /// Creates navigation route to new instance of [OnlineGameMasterScreen]
  static Route createNavigationRoute({LpsUser? invite}) =>
      MaterialPageRoute(builder: (_) => OnlineGameMasterScreen(invite: invite));

  @override
  Widget build(BuildContext context) =>
      AuthenticationView(onLoggedIn: (_) => OnlineHomeScreen(invite: invite));
}
