import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/friends.dart';
import 'package:lets_play_cities/screens/online/game_master.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';

/// What a push of an invitation or an invitation from another screen needs
/// from the open «Онлайн» screen. There is one online bloc per game
/// connection, so they go through the bloc of the screen that is open
/// instead of building a second one.
class OnlineHomeHandle {
  /// The open screen, `null` while none is open
  static OnlineHomeHandle? get current => _open.lastOrNull;

  /// The open screens, the newest last. More than one only while a screen
  /// replaces another, e.g. after a sign-in again.
  static final _open = <OnlineHomeHandle>[];

  final WaitingRoomBloc _bloc;
  final VoidCallback _showHome;

  OnlineHomeHandle._(this._bloc, this._showHome);

  /// Goes back to the screen and accepts the invitation of [fromId]
  void accept(int fromId) {
    _showHome();
    _bloc.add(ReplyToInvite(fromId, true));
  }

  /// Goes back to the screen and invites [friend]
  void invite(LpsUser friend) {
    _showHome();
    _bloc.add(InvitePressed(friend));
  }

  /// Declines the invitation of [fromId]; whatever the screen does goes on
  void decline(int fromId) => _bloc.add(ReplyToInvite(fromId, false));
}

/// «Онлайн»: the search card and up to three friends to invite. Needs the
/// signed-in [RemoteAccount] above it.
class OnlineHomeScreen extends StatefulWidget {
  /// Added as soon as the screen opens: an invitation of a friend, or the
  /// accepted invitation of a push
  final WaitingRoomEvent? initialEvent;

  /// Time of the queue timer
  final DateTime Function()? clock;

  /// Starts the game; by default pushes the game screen
  final StartGame? onStarting;

  const OnlineHomeScreen({
    super.key,
    this.initialEvent,
    @visibleForTesting this.clock,
    @visibleForTesting this.onStarting,
  });

  @override
  State<OnlineHomeScreen> createState() => _OnlineHomeScreenState();
}

class _OnlineHomeScreenState extends State<OnlineHomeScreen>
    with WidgetsBindingObserver {
  /// How many friends the screen shows
  static const _friendCount = 3;

  final ApiRepository _repository = GetIt.instance
      .get<ApiRepositoryFactory>()
      .forUser();

  late final WaitingRoomBloc _bloc = createWaitingRoomBloc(
    isLocal: false,
    clock: widget.clock,
  );

  // The cached list has an old online status
  late final Future<List<FriendEntry>> _friends = _repository.friends(true);

  late final OnlineHomeHandle _handle = OnlineHomeHandle._(_bloc, _showHome);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    OnlineHomeHandle._open.add(_handle);

    final initial = widget.initialEvent;
    if (initial != null) _bloc.add(initial);
  }

  @override
  void dispose() {
    OnlineHomeHandle._open.remove(_handle);
    WidgetsBinding.instance.removeObserver(this);
    _bloc.close();
    super.dispose();
  }

  /// In the background the search stops and the connection closes, unless a
  /// game runs; the next search connects again
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _bloc.add(const AppPaused());
  }

  /// Closes everything above this screen
  void _showHome() {
    final route = ModalRoute.of(context);
    Navigator.of(context).popUntil((r) => r == route);
  }

  /// Invites [friend] from a screen above this one: back here first
  void _invite(LpsUser friend) => _handle.invite(friend);

  void _signInAgain() =>
      Navigator.of(context)
          .pushReplacement(OnlineGameMasterScreen.createNavigationRoute());

  void _openFriends() {
    final t = context.t;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RepositoryProvider<ApiRepository>.value(
          value: _repository,
          child: Scaffold(
            appBar: AppBar(title: Text(t.online.friendsTab)),
            body: OnlineFriendsScreen(onInvite: _invite),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final account = context.watch<RemoteAccount>();

    return MultiRepositoryProvider(
      providers: [RepositoryProvider<ApiRepository>.value(value: _repository)],
      child: BlocProvider<WaitingRoomBloc>.value(
        value: _bloc,
        child: WaitingRoomView(
          onStarting: widget.onStarting,
          onUnauthorized: _signInAgain,
          child: Scaffold(
            backgroundColor: c.bg,
            body: SafeArea(
              child: Column(
                children: [
                  D2ScreenHeader(
                    title: t.online.title,
                    onBack: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        WaitingRoomCard(
                          clock: widget.clock,
                          avatar: Builder(
                            builder: (context) =>
                                lpsUserAvatar(context, account.user, size: 64),
                          ),
                        ),
                        // While an opponent is being looked for or waited
                        // for, nothing else is offered.
                        BlocBuilder<WaitingRoomBloc, WaitingRoomState>(
                          buildWhen: (a, b) => _isBusy(a) != _isBusy(b),
                          builder: (context, state) => _isBusy(state)
                              ? const SizedBox.shrink()
                              : FutureBuilder<List<FriendEntry>>(
                                  future: _friends,
                                  builder: (context, snapshot) => _FriendsBlock(
                                    loaded: snapshot.hasData,
                                    friends: _freshFriends(
                                      snapshot.data ?? const [],
                                    ),
                                    onInvite: _invite,
                                    onAll: _openFriends,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static bool _isBusy(WaitingRoomState state) => switch (state) {
    Connecting() || Queued() || Inviting() || Starting() => true,
    _ => false,
  };

  static List<LpsUser> _freshFriends(List<FriendEntry> entries) =>
      ([
            for (final entry in entries)
              if (entry.status == FriendStatus.friends) entry.user,
          ]..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt)))
          .take(_friendCount)
          .toList();
}

/// «Друзья» with «Все друзья». Without friends a hint of what will be here,
/// and nothing until the list is [loaded] or if it failed to load.
class _FriendsBlock extends StatelessWidget {
  final bool loaded;
  final List<LpsUser> friends;
  final void Function(LpsUser friend) onInvite;
  final VoidCallback onAll;

  const _FriendsBlock({
    required this.loaded,
    required this.friends,
    required this.onInvite,
    required this.onAll,
  });

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const SizedBox.shrink();

    final t = context.t;
    final c = D2Colors.of(context);

    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.online.friendsTab,
              style: D2Text.section.copyWith(fontSize: 16, color: c.ink),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.edge, width: 2),
              ),
              child: Row(
                children: [
                  D2Icon(D2Glyph.friends, size: 24, color: c.inkSoft),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.online.friendsHint,
                      style: D2Text.bodyRegular.copyWith(
                        fontSize: 14,
                        height: 1.35,
                        color: c.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.online.friendsTab,
                  style: D2Text.section.copyWith(fontSize: 16, color: c.ink),
                ),
              ),
              TextButton(
                onPressed: onAll,
                style: TextButton.styleFrom(
                  foregroundColor: c.violet,
                  minimumSize: const Size(44, 44),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.online.allFriends,
                      style: D2Text.body.copyWith(
                        fontSize: 14,
                        color: c.violet,
                      ),
                    ),
                    const SizedBox(width: 4),
                    D2Icon(D2Glyph.chevron, size: 18, color: c.violet),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          D2Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < friends.length; i++) ...[
                  if (i > 0) Container(height: 2, color: c.bg),
                  _FriendRow(user: friends[i], onInvite: onInvite),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final LpsUser user;
  final void Function(LpsUser friend) onInvite;

  const _FriendRow({required this.user, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final online = user.isOnline(DateTime.now());

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  lpsUserAvatar(context, user),
                  if (online)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: c.mint,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 3),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Semantics(
                  label: online
                      ? t.online.friendOnline(name: user.name)
                      : user.name,
                  excludeSemantics: true,
                  child: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: D2Text.body.copyWith(fontSize: 15, color: c.ink),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Large text cuts the label rather than the name to nothing
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * _buttonShare,
                ),
                child: D2Button(
                  label: t.online.inviteShort,
                  kind: D2ButtonKind.accent,
                  semanticLabel: t.online.inviteNamed(name: user.name),
                  onPressed: () => onInvite(user),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The widest the invite button gets, as a part of the row
  static const _buttonShare = 0.5;
}
