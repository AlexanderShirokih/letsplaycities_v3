import 'package:flutter/material.dart';
import 'package:lets_play_cities/screens/common/authentication_view.dart';
import 'package:lets_play_cities/screens/online/logged_in_game_master.dart';

/// Shows Log-in screen if user is not logged in yet or shows
/// [LoggedInOnlineGameMasterScreen].
class OnlineGameMasterScreen extends StatelessWidget {
  /// Creates navigation route to new instance of [OnlineGameMasterScreen]
  static Route createNavigationRoute() =>
      MaterialPageRoute(builder: (_) => OnlineGameMasterScreen());

  @override
  Widget build(BuildContext context) =>
      AuthenticationView(onLoggedIn: (_) => LoggedInOnlineGameMasterScreen());
}
