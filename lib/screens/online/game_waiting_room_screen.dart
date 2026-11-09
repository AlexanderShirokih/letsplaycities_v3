import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/client/api_exception.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/protocol/game_messages.dart'
    show InviteStatusKind, ProtocolError;
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';

/// Starts the game that a match built
typedef StartGame = void Function(BuildContext context, GameConfig config);

/// A [WaitingRoomBloc] over the [GameConnection] of the current GetIt scope.
/// [isLocal] says whether that connection goes to a LAN host.
WaitingRoomBloc createWaitingRoomBloc({
  required bool isLocal,
  DateTime Function()? clock,
}) {
  final getIt = GetIt.instance;

  return WaitingRoomBloc(
    RemoteGameClient(
      getIt.get<GameConnection>(),
      isLocal: isLocal,
      // The pictures are on the main server, also in a LAN game.
      pictureConfig: getIt.get<ApiRepositoryFactory>().serverConfig,
      chatEnabled: getIt.get<GamePreferences>().onlineChatEnabled,
    ),
    clock: clock,
  );
}

/// Declines the invitation of [fromId] over [connection] when no «Онлайн»
/// is open to do it, and closes the connection after the reply. A failure
/// is only logged: the invitation expires on the server anyway.
Future<void> declineInviteOverConnection(
  GameConnection connection,
  int fromId,
) async {
  final client = RemoteGameClient(connection, isLocal: false);

  try {
    await client.reply(fromId, false);
  } catch (e) {
    developer.log('Decline failed: $e', name: 'declineInvite');
  } finally {
    await client.disconnect();
  }
}

/// Pushes the game screen with a repository of the main server, also in a
/// LAN game.
void pushGameScreen(BuildContext context, GameConfig config) {
  final ApiRepository repository = GetIt.instance
      .get<ApiRepositoryFactory>()
      .forUser();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RepositoryProvider.value(
        value: repository,
        child: GameScreen(config),
      ),
    ),
  );
}

/// The text of a failed request under «Нет связи с сервером», `null` for the
/// hint to check the internet
String? waitingFailureText(Translations t, Exception error) => switch (error) {
  ProtocolErrorException(code: ProtocolError.replaced) => t.online.replaced,
  ProtocolErrorException(code: ProtocolError.unsupportedProtocol) =>
    t.online.updateApp,
  // Only a full LAN host refuses the hello with it
  ProtocolErrorException(code: ProtocolError.invalidState) => t.online.hostFull,
  ApiException() => errorText(t, error),
  _ => null,
};

/// The waiting room of a LAN game
class GameWaitingRoomScreenStandalone extends StatelessWidget {
  /// Whether the game connection goes to a LAN host
  final bool isLocal;

  const GameWaitingRoomScreenStandalone({super.key, required this.isLocal});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            D2ScreenHeader(
              title: isLocal
                  ? context.t.multiplayer.wifiTitle
                  : context.t.online.title,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: GameWaitingRoomScreen(isLocal: isLocal)),
          ],
        ),
      ),
    );
  }
}

/// The search card alone: the waiting room until the game starts
class GameWaitingRoomScreen extends StatelessWidget {
  /// Whether the game connection goes to a LAN host
  final bool isLocal;

  /// Starts the game; by default pushes the game screen
  final StartGame? onStarting;

  const GameWaitingRoomScreen({
    super.key,
    required this.isLocal,
    @visibleForTesting this.onStarting,
  });

  @override
  Widget build(BuildContext context) => BlocProvider<WaitingRoomBloc>(
    // Created once for this screen and closed with it; closing it also
    // closes the connection unless a game runs on it
    create: (_) => createWaitingRoomBloc(isLocal: isLocal),
    child: WaitingRoomView(
      onStarting: onStarting,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: const [WaitingRoomCard()],
      ),
    ),
  );
}

/// Shows [child] while the [WaitingRoomBloc] above works and «Нет связи»
/// when it failed; starts the game of a match.
class WaitingRoomView extends StatelessWidget {
  final Widget child;

  /// Starts the game; by default pushes the game screen
  final StartGame? onStarting;

  /// The server refused the token of the user; without it the failure is
  /// shown like any other
  final VoidCallback? onUnauthorized;

  const WaitingRoomView({
    super.key,
    required this.child,
    this.onStarting,
    this.onUnauthorized,
  });

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<WaitingRoomBloc, WaitingRoomState>(
        listener: (context, state) {
          if (state is Starting) {
            (onStarting ?? pushGameScreen)(context, state.config);
          } else if (state case Failed(error: UnauthorizedException())
              when onUnauthorized != null) {
            onUnauthorized!();
          }
        },
        builder: (context, state) {
          if (state is! Failed) return child;

          final bloc = context.read<WaitingRoomBloc>();

          return ConnectionErrorView(
            errorMessage: waitingFailureText(context.t, state.error),
            onReload: () => bloc.add(state.retry ?? const FindPressed()),
          );
        },
      );
}

/// The search card: «Найти соперника» at rest, «Подключаемся…», the radar
/// of the queue, or the status of the invitation
class WaitingRoomCard extends StatelessWidget {
  /// The player, in the middle of the radar
  final Widget? avatar;

  /// Time of the queue timer
  final DateTime Function()? clock;

  const WaitingRoomCard({super.key, this.avatar, this.clock});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WaitingRoomBloc, WaitingRoomState>(
        builder: (context, state) => D2Card(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Semantics(liveRegion: true, child: _content(context, state)),
        ),
      );

  Widget _content(BuildContext context, WaitingRoomState state) {
    final t = context.t;
    final c = D2Colors.of(context);
    final bloc = context.read<WaitingRoomBloc>();

    Widget find() => D2Button(
      label: t.online.connect,
      icon: D2Glyph.search,
      size: D2ButtonSize.large,
      expand: true,
      onPressed: () => bloc.add(const FindPressed()),
    );

    Widget cancel(String label) => D2Button(
      label: label,
      kind: D2ButtonKind.secondary,
      expand: true,
      onPressed: () => bloc.add(const CancelPressed()),
    );

    Widget title(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: D2Text.title.copyWith(color: c.ink),
    );

    Widget note(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: D2Text.bodyRegular.copyWith(color: c.inkSoft),
    );

    final children = switch (state) {
      Idle() || Starting() || Failed() => [find()],
      Connecting() => [
        D2Radar(size: 120, center: avatar),
        title(t.online.connectingToServer),
        cancel(t.cancel),
      ],
      Queued(:final since) => [
        D2Radar(size: 176, center: avatar),
        title(t.online.awaitingForOpp),
        _QueueTimer(since: since, clock: clock ?? DateTime.now),
        cancel(t.cancel),
      ],
      Inviting(:final target) => [
        D2Radar(size: 176, center: lpsUserAvatar(context, target, size: 64)),
        title(t.online.awaitingForInvite(login: target.name)),
        cancel(t.online.cancelInvite),
      ],
      InviteFinished(:final target, :final status) => [
        if (target != null) lpsUserAvatar(context, target, size: 64),
        note(_inviteResult(t, status, invited: target != null)),
        find(),
      ],
      RateLimited() => [note(t.online.rateLimited), find()],
      InviteReplyRejected() => [
        note(t.online.invitationResult.replyRejected),
        find(),
      ],
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          if (children[i] is D2Radar || children[i] is D2Avatar)
            Center(child: children[i])
          else
            children[i],
        ],
      ],
    );
  }

  static String _inviteResult(
    Translations t,
    InviteStatusKind status, {
    required bool invited,
  }) {
    final results = t.online.invitationResult;

    return switch (status) {
      InviteStatusKind.expired when !invited => results.replyExpired,
      InviteStatusKind.sent || InviteStatusKind.declined => results.declined,
      InviteStatusKind.busy => results.busy,
      InviteStatusKind.offline => results.offline,
      InviteStatusKind.notFriends => results.notFriends,
      InviteStatusKind.blocked => results.blocked,
      InviteStatusKind.expired => results.expired,
    };
  }
}

/// `m:ss` since [since], once a second
class _QueueTimer extends StatefulWidget {
  final DateTime since;
  final DateTime Function() clock;

  const _QueueTimer({required this.since, required this.clock});

  @override
  State<_QueueTimer> createState() => _QueueTimerState();
}

class _QueueTimerState extends State<_QueueTimer> {
  late final Timer _ticks;

  @override
  void initState() {
    super.initState();
    _ticks = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticks.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final elapsed = widget.clock().difference(widget.since);
    final seconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
    final text =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

    return Semantics(
      label: context.t.online.searchingFor(count: seconds),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          D2Icon(D2Glyph.timer, size: 16, color: c.inkSoft),
          const SizedBox(width: 6),
          Text(text, style: D2Text.section.copyWith(color: c.inkSoft)),
        ],
      ),
    );
  }
}
