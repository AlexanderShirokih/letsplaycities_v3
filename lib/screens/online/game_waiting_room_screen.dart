import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/remote/model/server_messages.dart';
import 'package:lets_play_cities/remote/models.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';

/// Screen used to start the
class GameWaitingRoomScreenStandalone extends StatelessWidget {
  /// If present, invitation or joining result will send to the
  /// [FriendGameRequest.target] user
  final FriendGameRequest? request;

  const GameWaitingRoomScreenStandalone({super.key, this.request});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: GameWaitingRoomScreen(request: request),
  );
}

/// Initial screen where user resides until game starts
class GameWaitingRoomScreen extends StatefulWidget {
  /// If present, invitation or joining result will send to the
  /// [FriendGameRequest.target] user
  final FriendGameRequest? request;

  const GameWaitingRoomScreen({super.key, this.request});

  @override
  State<GameWaitingRoomScreen> createState() => _GameWaitingRoomScreenState();
}

class _GameWaitingRoomScreenState extends State<GameWaitingRoomScreen> {
  late Future<RemoteAccount?> _account;

  @override
  void initState() {
    super.initState();
    _account = _fetchAccount();
  }

  Future<RemoteAccount?> _fetchAccount() =>
      GetIt.instance.get<AccountManager>().getLastSignedInAccount();

  @override
  Widget build(BuildContext context) {
    final getIt = GetIt.instance;
    final request = widget.request;

    return FutureBuilder<RemoteAccount?>(
      future: _account,
      builder: (context, account) {
        final t = context.t;
        if (account.connectionState != ConnectionState.done) {
          return LoadingView(t.online.fetchingProfile);
        }

        final remoteAccount = account.data;
        if (remoteAccount == null) {
          return ConnectionErrorView(
            onReload: () => setState(() {
              _account = _fetchAccount();
            }),
            errorMessage: switch (account.error) {
              AuthorizationException error => authorizationErrorText(t, error),
              null => t.online.authFailed,
              _ => null,
            },
          );
        }

        // The provider creates the bloc once for this screen and closes it,
        // and with it the socket, when the screen goes away.
        return BlocProvider<WaitingRoomBloc>(
          create: (_) {
            final waitingBloc = WaitingRoomBloc(
              RemoteGameClient(
                getIt<GameConnection>(),
                isLocal: !getIt<AppConfig>().isSecure,
                // The pictures are on the main server, also in a LAN game.
                pictureConfig: getIt<ApiRepositoryFactory>().pictureConfig,
                chatEnabled: getIt<GamePreferences>().onlineChatEnabled,
              ),
              remoteAccount.userId,
              apiRepositories: () => getIt<ApiRepositoryFactory>(),
            );

            if (request != null) {
              waitingBloc.add(NewGameRequestEvent(request));
            }
            return waitingBloc;
          },
          child: WaitingRoomView(request: request),
        );
      },
    );
  }
}

/// Shows the state of the [WaitingRoomBloc] provided above it.
class WaitingRoomView extends StatelessWidget {
  /// Friend-mode request the screen was opened with, `null` in random mode.
  /// Connect buttons send it again, so a retry stays a friend game.
  final FriendGameRequest? request;

  const WaitingRoomView({super.key, this.request});

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<WaitingRoomBloc, WaitingRoomState>(
        builder: (context, state) {
          if (state is WaitingRoomInitial) {
            return _ReadyToConnectView(request);
          } else if (state is WaitingRoomConnectingState) {
            return _WaitingForConnectionView(state.connectionStage);
          } else if (state is WaitingForOpponentsState) {
            return _WaitingForOpponentsView(request: state.request);
          } else if (state is WaitingRoomAuthorizationFailed) {
            return _TextWithBigIconView(
              icon: FaIcon(FontAwesomeIcons.userSlash),
              message: state.description ?? context.t.online.authFailed,
            );
          } else if (state is WaitingRoomConnectionError) {
            return _TextWithBigIconView(
              icon: Icon(Icons.wifi_off),
              message: context.t.online.connectionError,
              buttonType: ButtonType.connect,
              request: request,
            );
          } else if (state is WaitingRoomInvitationNegativeResult) {
            return _InvitationNegativeResult(
              result: state.result,
              target: state.target,
            );
          } else {
            return _TextWithBigIconView(
              icon: Icon(Icons.timer),
              message: '...',
              buttonType: ButtonType.cancel,
            );
          }
        },
        listener: (context, state) {
          if (state is StartGameState) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RepositoryProvider.value(
                  value: state.apiRepository,
                  child: GameScreen(state.config),
                ),
              ),
            );
          }
        },
      );
}

/// Initial view that shows 'connect' button
class _ReadyToConnectView extends StatelessWidget {
  /// Sent by the connect button, `null` in random mode.
  final FriendGameRequest? request;

  const _ReadyToConnectView(this.request);

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Text(
            context.t.online.gameDesc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 18.0),
        _createConnectButton(context, request),
      ],
    ),
  );
}

/// View, used until user connects to the server
class _WaitingForConnectionView extends StatelessWidget {
  final ConnectionStage _connectionStage;

  const _WaitingForConnectionView(this._connectionStage);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getStateDescription(context.t),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: CircularProgressIndicator(),
          ),
          _createCancelButton(context),
        ],
      ),
    );
  }

  String _getStateDescription(Translations t) {
    switch (_connectionStage) {
      case ConnectionStage.awaitingConnection:
        return t.online.connectingToServer;
      case ConnectionStage.authorization:
        return t.online.authorization;
      case ConnectionStage.done:
        return t.online.connected;
    }
  }
}

enum ButtonType { connect, cancel }

/// Shows text and big icon on center
class _TextWithBigIconView extends StatelessWidget {
  final String message;
  final Widget icon;
  final ButtonType? buttonType;

  /// Sent by the connect button, `null` in random mode.
  final FriendGameRequest? request;

  const _TextWithBigIconView({
    required this.message,
    required this.icon,
    this.buttonType,
    this.request,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconTheme(
                data: IconThemeData(
                  color: Theme.of(context).hintColor,
                  size: 64.0,
                ),
                child: icon,
              ),
            ),
            Text(message, textAlign: TextAlign.center),
            if (buttonType == ButtonType.connect)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: _createConnectButton(context, request),
              )
            else if (buttonType == ButtonType.cancel)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: _createCancelButton(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// Used when waiting for opponents. Shows animation and text.
class _WaitingForOpponentsView extends StatefulWidget {
  static List<FaIconData> dices = [
    FontAwesomeIcons.diceOne,
    FontAwesomeIcons.diceTwo,
    FontAwesomeIcons.diceThree,
    FontAwesomeIcons.diceFour,
    FontAwesomeIcons.diceFive,
    FontAwesomeIcons.diceSix,
  ];

  /// Used in friend game mode. In random mode mode will be `null`.
  final FriendGameRequest? request;

  const _WaitingForOpponentsView({this.request});

  @override
  State<_WaitingForOpponentsView> createState() =>
      __WaitingForOpponentsViewState();
}

class __WaitingForOpponentsViewState extends State<_WaitingForOpponentsView>
    with TickerProviderStateMixin, NetworkAvatarBuildingMixin {
  late final FaIconData _dice;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    final dices = _WaitingForOpponentsView.dices;
    _dice = dices[Random().nextInt(dices.length)];
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ).drive(Tween<double>(begin: 0.5, end: 1.0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: IconTheme(
                  data: IconThemeData(
                    color: Theme.of(context).hintColor,
                    size: 64.0,
                  ),
                  child: FaIcon(_dice),
                ),
              ),
            ),
            if (widget.request != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: buildAvatar(widget.request!.target),
              ),
            Text(
              widget.request == null
                  ? context.t.online.awaitingForOpp
                  : context.t.online.awaitingForInvite(
                      login: widget.request!.target.login,
                    ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64.0),
              child: widget.request != null
                  ? _createBackButton(context)
                  : _createCancelButton(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Creates view with invitation result message
class _InvitationNegativeResult extends StatelessWidget
    with NetworkAvatarBuildingMixin {
  final InviteResultType result;
  final BaseProfileInfo target;

  const _InvitationNegativeResult({required this.result, required this.target});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 6.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 24.0),
              child: buildAvatar(target, 60.0),
            ),
            Text(
              _describeResult(context),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _createBackButton(context),
            ),
          ],
        ),
      ),
    );
  }

  String _describeResult(BuildContext context) {
    final results = context.t.online.invitationResult;
    return switch (result) {
      InviteResultType.busy => results.busy,
      InviteResultType.denied => results.denied,
      InviteResultType.noUser => results.noUser,
      InviteResultType.notFriend => results.notFriend,
    };
  }
}

Widget _createBackButton(BuildContext context) => createStyledMaterialButton(
  context,
  FaIcon(FontAwesomeIcons.angleLeft),
  context.t.back,
  () => Navigator.of(context).pop(),
);

Widget _createCancelButton(BuildContext context) => ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).primaryColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  onPressed: () => context.read<WaitingRoomBloc>().add(CancelEvent()),
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: Text(context.t.cancel),
  ),
);

Widget _createConnectButton(BuildContext context, FriendGameRequest? request) =>
    createStyledMaterialButton(
      context,
      FaIcon(FontAwesomeIcons.dice),
      context.t.online.connect,
      () => context.read<WaitingRoomBloc>().add(NewGameRequestEvent(request)),
    );
