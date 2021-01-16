import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/client/json_message_converter.dart';
import 'package:lets_play_cities/remote/client/remote_game_client.dart';
import 'package:lets_play_cities/remote/client/socket_api.dart';
import 'package:lets_play_cities/remote/client/web_socket_connector.dart';
import 'package:lets_play_cities/remote/model/incoming_models.dart';
import 'package:lets_play_cities/remote/models.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

class GameWaitingRoomScreenStandalone extends StatelessWidget {
  /// If present, invitation will send to the [target] user
  final BaseProfileInfo target;

  const GameWaitingRoomScreenStandalone(this.target);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: GameWaitingRoomScreen(target: target),
      );
}

/// Initial screen where user resides until game starts
class GameWaitingRoomScreen extends StatelessWidget {
  /// If present, invitation will send to the [target] user
  final BaseProfileInfo? target;

  const GameWaitingRoomScreen({
    Key? key,
    this.target,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RemoteAccount?>(
      future: context.watch<AccountManager>().getLastSignedInAccount(),
      builder: (context, account) {
        if (!account.hasData) {
          return buildWithLocalization(
              context, (l10n) => LoadingView(l10n.online['fetching_profile']));
        }

        return BlocProvider.value(
          value: WaitingRoomBloc(
            RemoteGameClient(
              account: account.requireData!,
              firebaseToken: Future.value(null),
              preferences: context.watch<GamePreferences>(),
              socketApi: SocketApi(
                WebSocketConnector(AppConfig.remoteWebSocketURL),
                JsonMessageConverter(),
              ),
            ),
            account.requireData!.credential,
            target,
          ),
          child: BlocConsumer<WaitingRoomBloc, WaitingRoomState>(
            builder: (context, state) {
              if (state is WaitingRoomInitial) {
                return _ReadyToConnectView();
              } else if (state is WaitingRoomConnectingState) {
                return _WaitingForConnectionView(state.connectionStage);
              } else if (state is WaitingForOpponentsState) {
                return _WaitingForOpponentsView(target: state.target);
              } else if (state is WaitingRoomAuthorizationFailed) {
                return _TextWithBigIconView(
                  icon: FaIcon(FontAwesomeIcons.userAltSlash),
                  message: state.description ??
                      buildWithLocalization(
                          context, (l10n) => l10n.online['auth_failed']),
                );
              } else if (state is WaitingRoomConnectionError) {
                return _TextWithBigIconView(
                  icon: Icon(Icons.wifi_off),
                  message: buildWithLocalization(
                      context, (l10n) => l10n.online['connection_error']),
                  buttonType: ButtonType.connect,
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
                    builder: (_) => MultiRepositoryProvider(
                      providers: [
                        RepositoryProvider.value(
                            value: context.read<ApiRepository>()),
                        RepositoryProvider.value(
                            value: context.read<AccountManager>()),
                      ],
                      child: GameScreen(state.config),
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

/// Initial view that shows 'connect' button
class _ReadyToConnectView extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: buildWithLocalization(
          context,
          (l10n) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Text(
                  l10n.online['game_desc'],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              const SizedBox(height: 18.0),
              _createConnectButton(context),
            ],
          ),
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
      child: buildWithLocalization(
        context,
        (l10n) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getStateDescription(l10n),
              style: Theme.of(context).textTheme.headline6,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: CircularProgressIndicator(),
            ),
            _createCancelButton(context),
          ],
        ),
      ),
    );
  }

  String _getStateDescription(LocalizationService l10n) {
    switch (_connectionStage) {
      case ConnectionStage.awaitingConnection:
        return l10n.online['connecting_to_server'];
      case ConnectionStage.authorization:
        return l10n.online['authorization'];
      case ConnectionStage.done:
        return l10n.online['connected'];
      default:
        return '...';
    }
  }
}

enum ButtonType { connect, cancel }

/// Shows text and big icon on center
class _TextWithBigIconView extends StatelessWidget {
  final String message;
  final Widget icon;
  final ButtonType? buttonType;

  const _TextWithBigIconView({
    Key? key,
    required this.message,
    required this.icon,
    this.buttonType,
  }) : super(key: key);

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
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (buttonType == ButtonType.connect)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: _createConnectButton(context),
              )
            else if (buttonType == ButtonType.cancel)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: _createCancelButton(context),
              )
          ],
        ),
      ),
    );
  }
}

/// Used when waiting for opponents. Shows animation and text.
class _WaitingForOpponentsView extends StatefulWidget {
  static List<IconData> dices = [
    FontAwesomeIcons.diceOne,
    FontAwesomeIcons.diceTwo,
    FontAwesomeIcons.diceThree,
    FontAwesomeIcons.diceFour,
    FontAwesomeIcons.diceFive,
    FontAwesomeIcons.diceSix,
  ];

  /// Used in invitation mode. In random mode mode will be `null`.
  final BaseProfileInfo? target;

  const _WaitingForOpponentsView({Key? key, this.target}) : super(key: key);

  @override
  __WaitingForOpponentsViewState createState() {
    return __WaitingForOpponentsViewState(
        dices[Random().nextInt(dices.length)]);
  }
}

class __WaitingForOpponentsViewState extends State<_WaitingForOpponentsView>
    with TickerProviderStateMixin, NetworkAvatarBuildingMixin {
  final IconData _dice;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  __WaitingForOpponentsViewState(this._dice);

  @override
  void initState() {
    super.initState();
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
            if (widget.target != null)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: buildAvatar(widget.target!),
              ),
            buildWithLocalization(
              context,
              (l10n) => Text(
                widget.target == null
                    ? l10n.online['awaiting_for_opp']
                    : (l10n.online['awaiting_for_invite'] as String)
                        .format([widget.target!.login]),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64.0),
              child: widget.target != null
                  ? _createBackButton(context)
                  : _createCancelButton(context),
            )
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

  const _InvitationNegativeResult({
    Key? key,
    required this.result,
    required this.target,
  }) : super(key: key);

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
              style: Theme.of(context).textTheme.headline6,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: _createBackButton(context),
            )
          ],
        ),
      ),
    );
  }

  String _describeResult(BuildContext context) => buildWithLocalization(
      context, (l10n) => l10n.online['invitation_result'][result.index]);
}

Widget _createBackButton(BuildContext context) => createStyledMaterialButton(
      context,
      FaIcon(FontAwesomeIcons.angleLeft),
      buildWithLocalization(context, (l10n) => l10n.back),
      () => Navigator.of(context).pop(),
    );

Widget _createCancelButton(BuildContext context) => RaisedButton(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: buildWithLocalization(context, (l10n) => Text(l10n.cancel)),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      onPressed: () => context.read<WaitingRoomBloc>().add(CancelEvent()),
    );

Widget _createConnectButton(BuildContext context) => createStyledMaterialButton(
      context,
      FaIcon(FontAwesomeIcons.dice),
      buildWithLocalization(
        context,
        (l10n) => l10n.online['connect'],
      ),
      () => context.read<WaitingRoomBloc>().add(ConnectEvent()),
    );
