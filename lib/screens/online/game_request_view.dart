import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/multiplayer/lan_scope.dart';
import 'package:lets_play_cities/screens/online/game_master.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';
import 'package:lets_play_cities/screens/online/online_home_screen.dart';

/// The content of the sheet for the push that invites to a game: who invites
/// and «Принять» / «Отклонить». Both answers go over the one game
/// connection of the main server: through the open «Онлайн», or, when none
/// is open, accept opens it and decline connects for the reply alone.
class GameRequestView extends StatefulWidget {
  final GameRequest request;

  /// The game connection and the API of the main server, also while a LAN
  /// game runs and the ones in [GetIt] go to the LAN host
  final GameConnection connection;
  final ApiRepositoryFactory apiRepositories;

  const GameRequestView({
    super.key,
    required this.request,
    required this.connection,
    required this.apiRepositories,
  });

  @override
  State<GameRequestView> createState() => _GameRequestViewState();
}

class _GameRequestViewState extends State<GameRequestView> {
  late final ApiRepository _repository = widget.apiRepositories.forUser();

  // Fetched once: the sheet rebuilds this view while it is dragged. The
  // picture is a nicety, so a failure only leaves the initial.
  late final Future<String?> _pictureUrl = _fetchPictureUrl();

  Future<String?> _fetchPictureUrl() async {
    try {
      final profile = await _repository.user(widget.request.fromId);

      return _repository.avatarUrl(profile.user);
    } catch (_) {
      return null;
    }
  }

  void _accept() {
    final home = OnlineHomeHandle.current;
    if (home != null) {
      // Pops the sheet with everything else above «Онлайн»
      home.accept(widget.request.fromId);

      return;
    }

    final navigator = Navigator.of(context);
    navigator.pop();
    unawaited(
      navigator.push(
        OnlineGameMasterScreen.createNavigationRoute(
          initialEvent: ReplyToInvite(widget.request.fromId, true),
        ),
      ),
    );
  }

  void _decline() {
    final fromId = widget.request.fromId;
    final home = OnlineHomeHandle.current;
    Navigator.of(context).pop();

    if (home != null) {
      home.decline(fromId);
    } else {
      unawaited(declineInviteOverConnection(widget.connection, fromId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final name = widget.request.fromName;
    // A running game cannot take another one: the server would answer
    // invalid_state
    final canAccept =
        !RemoteGameClient.isGameRunningOn(widget.connection) &&
        GetIt.instance.currentScopeName != lanGameScopeName;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: FutureBuilder<String?>(
              future: _pictureUrl,
              builder: (context, picture) => D2Avatar.user(
                pictureUrl: picture.data,
                initials: nameInitial(name),
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t.online.invitesYou(name: name),
            textAlign: TextAlign.center,
            style: D2Text.title.copyWith(color: c.ink),
          ),
          const SizedBox(height: 16),
          if (canAccept) ...[
            D2Button(
              label: t.accept,
              size: D2ButtonSize.large,
              expand: true,
              onPressed: _accept,
            ),
            const SizedBox(height: 10),
          ],
          D2Button(
            label: t.decline,
            kind: D2ButtonKind.secondary,
            expand: true,
            onPressed: _decline,
          ),
        ],
      ),
    );
  }
}
