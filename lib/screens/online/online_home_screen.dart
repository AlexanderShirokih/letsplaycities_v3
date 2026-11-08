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

/// «Онлайн»: the search card and up to three friends to invite. Needs the
/// signed-in [RemoteAccount] above it.
class OnlineHomeScreen extends StatefulWidget {
  /// Invited as soon as the screen opens
  final LpsUser? invite;

  /// Time of the queue timer
  final DateTime Function()? clock;

  /// Starts the game; by default pushes the game screen
  final StartGame? onStarting;

  const OnlineHomeScreen({
    super.key,
    this.invite,
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final friend = widget.invite;
    if (friend != null) _bloc.add(InvitePressed(friend));
  }

  @override
  void dispose() {
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

  /// Invites [friend] from a screen above this one: back here first
  void _invite(LpsUser friend) {
    final route = ModalRoute.of(context);
    Navigator.of(context).popUntil((r) => r == route);
    _bloc.add(InvitePressed(friend));
  }

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
                        FutureBuilder<List<FriendEntry>>(
                          future: _friends,
                          builder: (context, snapshot) => _FriendsBlock(
                            friends: _freshFriends(snapshot.data ?? const []),
                            onInvite: _invite,
                            onAll: _openFriends,
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

  static List<LpsUser> _freshFriends(List<FriendEntry> entries) =>
      ([
            for (final entry in entries)
              if (entry.status == FriendStatus.friends) entry.user,
          ]..sort((a, b) => b.lastSeenAt.compareTo(a.lastSeenAt)))
          .take(_friendCount)
          .toList();
}

/// «Друзья» with «Все друзья», hidden without friends
class _FriendsBlock extends StatelessWidget {
  final List<LpsUser> friends;
  final void Function(LpsUser friend) onInvite;
  final VoidCallback onAll;

  const _FriendsBlock({
    required this.friends,
    required this.onInvite,
    required this.onAll,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();

    final t = context.t;
    final c = D2Colors.of(context);

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
