import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/app_injection.dart';
import 'package:lets_play_cities/base/platform/device_name.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/remote/bloc/local_multiplayer_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/game_connection.dart';
import 'package:lets_play_cities/remote/remote_host.dart';
import 'package:lets_play_cities/remote/server/server_game_controller.dart';
import 'package:lets_play_cities/remote/server/user_lookup_repository.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

import 'searching_hosts_screen.dart';

/// Waiting room for local multiplayer games
class LocalMultiplayerScreen extends StatelessWidget {
  const LocalMultiplayerScreen({super.key});

  /// Crates navigation route to show [LocalMultiplayerScreen]
  static Route createNavigationRoute(BuildContext context) => MaterialPageRoute(
    builder: (_) => LocalMultiplayerScreen(),
    settings: RouteSettings(name: 'multiplayer'),
  );

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final getIt = GetIt.instance;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: BlocProvider(
          create: (_) => LocalMultiplayerBloc(
            server: getIt.get<ServerGameController>(),
            errorLogger: getIt.get<ErrorLogger>(),
            localConfig: getIt.get<AppConfig>(instanceName: 'local'),
            // Resolved when a game starts, as the 'local' factory reads the
            // unnamed AccountManager, which a LAN scope may override.
            createAccountManager: (config) => getIt.get<AccountManager>(
              instanceName: 'local',
              param1: config,
            ),
          ),
          child: BlocConsumer<LocalMultiplayerBloc, LocalMultiplayerState>(
            builder: (context, state) => Column(
              children: [
                D2ScreenHeader(
                  title: t.multiplayer.wifiTitle,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: _ActionsView(
                    isStarting: state is LocalMultiplayerStartingServer,
                  ),
                ),
              ],
            ),
            listener: (context, state) {
              if (state is LocalMultiplayerStartGame) {
                final getIt = GetIt.instance;
                pushLanGameScope(getIt, state);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GameWaitingRoomScreenStandalone(),
                  ),
                ).then((value) => getIt.popScope());
              } else if (state is LocalMultiplayerNoWifiState) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.multiplayer.reconnectWifi)),
                );
              } else if (state is LocalMultiplayerErrorState) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(t.multiplayer.error)));
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Pushes the [getIt] scope of the LAN game that [game] starts. Inside it the
/// unnamed [AppConfig], the [AccountManager] and the [ApiRepositoryFactory]
/// target the LAN server; the factory keeps the picture URLs and the cache of
/// the one outside the scope.
@visibleForTesting
void pushLanGameScope(GetIt getIt, LocalMultiplayerStartGame game) {
  final apiRepositories = getIt.get<ApiRepositoryFactory>();
  getIt
    ..pushNewScope()
    ..registerSingleton<AppConfig>(game.configOverrides)
    ..registerSingleton<AccountManager>(game.accountManagerOverrides)
    ..registerSingleton<ApiRepositoryFactory>(
      apiRepositories.forServer(game.configOverrides, MemoryTokenStore()),
    )
    ..registerSingleton<UserLookupRepository>(UserLookupRepositoryImpl())
    // The LAN host never gets the token of the main server
    ..registerSingleton<GameConnection>(
      createGameConnection(
        url: game.configOverrides.gameSocketUrl,
        headers: () async => const {},
        playerName: () => getIt.get<GamePreferences>().lastNativeLogin,
      ),
      dispose: (connection) => connection.close(),
    );
}

/// Name of this device, `null` when it is not known
String? _deviceName() {
  try {
    return DeviceNameService.instance.deviceName;
  } catch (_) {
    return null;
  }
}

/// `create game` (or the waiting card instead of it) and `join` cards
class _ActionsView extends StatelessWidget {
  final bool isStarting;

  const _ActionsView({required this.isStarting});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final bloc = context.read<LocalMultiplayerBloc>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        if (isStarting)
          _WaitingCard(deviceName: _deviceName())
        else
          _ActionCard(
            color: c.orange,
            foreground: D2Colors.light.ink,
            title: t.multiplayer.createGame,
            illustration: D2Glyph.phone,
            action: D2Glyph.plus,
            onTap: () => bloc.add(const LocalMultiplayerCreate()),
          ),
        const SizedBox(height: 16),
        _ActionCard(
          color: c.violet,
          foreground: D2Colors.light.surface,
          title: t.multiplayer.join,
          illustration: D2Glyph.search,
          action: D2Glyph.back,
          flipAction: true,
          onTap: () =>
              Navigator.push<RemoteHost?>(
                context,
                MaterialPageRoute(builder: (_) => SearchingHostsScreen()),
              ).then((selectedHost) {
                if (selectedHost != null && context.mounted) {
                  bloc.add(LocalMultiplayerConnect(selectedHost));
                }
              }),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            D2Icon(D2Glyph.wifi, size: 18, color: c.inkSoft),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                t.multiplayer.sameWifi,
                style: D2Text.caption.copyWith(color: c.inkSoft, fontSize: 14),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Large colored card in a hard shadow
class _CardFrame extends StatelessWidget {
  final Color color;
  final Widget child;

  const _CardFrame({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: c.shadow.withAlpha(56), offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Color color;
  final Color foreground;
  final String title;
  final D2Glyph illustration;
  final D2Glyph action;
  final bool flipAction;
  final VoidCallback onTap;

  const _ActionCard({
    required this.color,
    required this.foreground,
    required this.title,
    required this.illustration,
    required this.action,
    required this.onTap,
    this.flipAction = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget actionIcon = D2Icon(action, color: D2Colors.light.ink);
    if (flipAction) {
      actionIcon = Transform.flip(flipX: true, child: actionIcon);
    }

    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _CardFrame(
          color: color,
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                child: D2Icon(
                  illustration,
                  size: 110,
                  strokeWidth: 2,
                  color: foreground.withAlpha(90),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: D2Text.title.copyWith(
                      color: foreground,
                      fontSize: 21,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: D2Colors.light.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: actionIcon,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown while the server starts: the host is visible nearby
class _WaitingCard extends StatelessWidget {
  final String? deviceName;

  const _WaitingCard({required this.deviceName});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final ink = D2Colors.light.ink;
    final text = D2Text.body.copyWith(color: ink, fontSize: 15);

    return _CardFrame(
      color: D2Colors.of(context).orange,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.multiplayer.visibleNearby,
                style: D2Text.title.copyWith(
                  color: ink,
                  fontSize: 21,
                  height: 1.15,
                ),
              ),
              if (deviceName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    D2Icon(D2Glyph.phone, size: 18, color: ink),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        t.multiplayer.deviceMode(device: deviceName!),
                        style: text,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          Row(
            children: [
              SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: ink,
                  backgroundColor: ink.withAlpha(76),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(t.multiplayer.waitingOpponent, style: text)),
              const SizedBox(width: 8),
              D2Button(
                label: t.multiplayer.cancelCreate,
                kind: D2ButtonKind.secondary,
                onPressed: () => context.read<LocalMultiplayerBloc>().add(
                  const LocalMultiplayerCancel(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
