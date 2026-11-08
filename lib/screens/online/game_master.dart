import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/screens/common/authentication_view.dart';
import 'package:lets_play_cities/screens/online/online_home_screen.dart';

/// Signs the user in if needed and shows [OnlineHomeScreen]
class OnlineGameMasterScreen extends StatelessWidget {
  /// Added as soon as «Онлайн» opens, e.g. the accepted invitation of a push
  final WaitingRoomEvent? initialEvent;

  const OnlineGameMasterScreen({super.key, this.initialEvent});

  /// Creates navigation route to new instance of [OnlineGameMasterScreen]
  static Route createNavigationRoute({WaitingRoomEvent? initialEvent}) =>
      MaterialPageRoute(
        builder: (_) => OnlineGameMasterScreen(initialEvent: initialEvent),
      );

  @override
  Widget build(BuildContext context) => AuthenticationView(
    onLoggedIn: (_) => OnlineHomeScreen(initialEvent: initialEvent),
  );
}
