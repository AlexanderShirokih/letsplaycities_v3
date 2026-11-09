import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/game/game_config.dart';
import 'package:lets_play_cities/base/game/game_mode.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/game_screen.dart';
import 'package:lets_play_cities/screens/game/hotseat_setup_screen.dart';
import 'package:lets_play_cities/screens/main/home_art.dart';
import 'package:lets_play_cities/screens/multiplayer/local_multiplayer_screen.dart';
import 'package:lets_play_cities/screens/online/game_master.dart';
import 'package:lets_play_cities/screens/root/root_screen.dart';
import 'package:lets_play_cities/screens/settings/settings_screen.dart';

/// What the home screen does on taps
class HomeActions {
  final VoidCallback playVsComputer;
  final VoidCallback playTwoPlayers;
  final VoidCallback playWifi;
  final VoidCallback playOnline;
  final VoidCallback openSettings;
  final VoidCallback openProfile;

  const HomeActions({
    required this.playVsComputer,
    required this.playTwoPlayers,
    required this.playWifi,
    required this.playOnline,
    required this.openSettings,
    required this.openProfile,
  });

  factory HomeActions.navigation(BuildContext context) {
    void push(Route<void> Function() route) =>
        Navigator.of(context).push(route());

    return HomeActions(
      playVsComputer: () => push(
        () => GameScreen.createGameScreenRoute(
          GameConfig(gameMode: GameMode.playerVsAndroid),
        ),
      ),
      playTwoPlayers: () => push(
        () => MaterialPageRoute(builder: (_) => const HotseatSetupScreen()),
      ),
      playWifi: () =>
          push(() => LocalMultiplayerScreen.createNavigationRoute(context)),
      playOnline: () => push(OnlineGameMasterScreen.createNavigationRoute),
      openSettings: () =>
          push(() => MaterialPageRoute(builder: (_) => SettingsScreen())),
      openProfile: () => RootScreen.of(context).select(2),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final HomeActions? actions;

  /// Loads the signed-in account for the avatar; by default the
  /// [AccountManager] of GetIt does
  final Future<RemoteAccount?> Function()? loadAccount;

  /// Tells that the account changed and has to be loaded again; by default
  /// the [AccountManager] of GetIt does
  final Stream<void>? accountChanges;

  const HomeScreen({
    super.key,
    this.actions,
    this.loadAccount,
    this.accountChanges,
  });

  @override
  Widget build(BuildContext context) {
    final a = actions ?? HomeActions.navigation(context);
    final t = context.t;
    final c = D2Colors.of(context);

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: t.d2.logoSemantics,
                      header: true,
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          const D2Logo(size: 34),
                          const SizedBox(width: 6),
                          // A large text scale shrinks the wordmark instead
                          // of pushing the buttons out
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                t.home.title,
                                style: D2Text.title.copyWith(
                                  fontSize: 20,
                                  color: c.ink,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  D2IconButton(
                    D2Glyph.settings,
                    tooltip: t.home.settings,
                    onPressed: a.openSettings,
                  ),
                  const SizedBox(width: 10),
                  Semantics(
                    label: t.home.profile,
                    button: true,
                    excludeSemantics: true,
                    onTap: a.openProfile,
                    child: Tooltip(
                      message: t.home.profile,
                      child: GestureDetector(
                        onTap: a.openProfile,
                        child: _AccountAvatar(
                          load:
                              loadAccount ??
                              () => GetIt.instance
                                  .get<AccountManager>()
                                  .getLastSignedInAccount(),
                          changes: accountChanges,
                          fallbackName: t.players.player,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ComputerCard(onPlay: a.playVsComputer),
              const SizedBox(height: 14),
              SizedBox(
                height: 248,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _ModeTile(
                        color: c.mint,
                        art: HomeArt.twoPlayers,
                        label: t.home.twoPlayers,
                        fontSize: 17,
                        onTap: a.playTwoPlayers,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _ModeTile(
                              color: c.sky,
                              art: HomeArt.wifi,
                              label: t.home.wifi,
                              onTap: a.playWifi,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _ModeTile(
                              color: c.yellow,
                              art: HomeArt.online,
                              label: t.home.online,
                              onTap: a.playOnline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar of the signed-in account, or the initial of [fallbackName]
class _AccountAvatar extends StatefulWidget {
  final Future<RemoteAccount?> Function() load;
  final Stream<void>? changes;
  final String fallbackName;

  const _AccountAvatar({
    required this.load,
    required this.changes,
    required this.fallbackName,
  });

  @override
  State<_AccountAvatar> createState() => _AccountAvatarState();
}

class _AccountAvatarState extends State<_AccountAvatar> {
  RemoteAccount? _account;
  StreamSubscription<void>? _changes;

  /// Tells a stale load from the current one
  int _loads = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _changes = _changeStream()?.listen((_) => _load());
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Stream<void>? _changeStream() {
    if (widget.changes != null) return widget.changes;

    try {
      return GetIt.instance.get<AccountManager>().accountChanges;
    } catch (_) {
      // No account manager: the avatar never changes.
      return null;
    }
  }

  Future<void> _load() async {
    final load = ++_loads;
    RemoteAccount? account;
    try {
      account = await widget.load();
    } catch (_) {
      // Offline: the home screen keeps what it shows.
      return;
    }

    // A sign-out gives `null`: the home screen shows the local player.
    if (mounted && load == _loads) setState(() => _account = account);
  }

  @override
  Widget build(BuildContext context) {
    final name = _account?.name ?? widget.fallbackName;

    return D2Avatar.user(
      pictureUrl: _account?.avatarUrl,
      initials: name.isEmpty ? '' : name.substring(0, 1).toUpperCase(),
      size: 44,
    );
  }
}

class _ComputerCard extends StatelessWidget {
  final VoidCallback onPlay;

  const _ComputerCard({required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return _Card(
      color: c.orange,
      height: 200,
      child: Stack(
        children: [
          const Positioned.fill(child: HomeCardArt(HomeArt.computer)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 190),
                    child: Text(
                      context.t.home.vsComputer,
                      style: D2Text.title.copyWith(
                        fontSize: 20,
                        height: 1.15,
                        color: c.shadow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  D2Button(
                    label: context.t.home.play,
                    icon: D2Glyph.play,
                    kind: D2ButtonKind.onCard,
                    size: D2ButtonSize.card,
                    onPressed: onPlay,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Colored card of the home screen with a radius of 24 and a soft shadow
class _Card extends StatelessWidget {
  final Color color;
  final double? height;
  final Widget child;

  const _Card({required this.color, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final radius = BorderRadius.circular(24);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: c.shadow.withValues(alpha: 0.22),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final Color color;
  final HomeArt art;
  final String label;
  final double fontSize;
  final VoidCallback onTap;

  const _ModeTile({
    required this.color,
    required this.art,
    required this.label,
    required this.onTap,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _Card(
          color: color,
          child: Stack(
            children: [
              Positioned.fill(child: HomeCardArt(art)),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: D2Text.title.copyWith(
                      fontSize: fontSize,
                      height: 1.15,
                      color: c.shadow,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
