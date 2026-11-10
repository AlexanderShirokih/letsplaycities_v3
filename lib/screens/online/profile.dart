import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/waiting_room_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/i18n/last_seen.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/account.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/banlist.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/friends.dart';
import 'package:lets_play_cities/screens/online/game_master.dart';
import 'package:lets_play_cities/screens/online/history.dart';
import 'package:lets_play_cities/screens/online/online_home_screen.dart';

import 'avatars/avatar_chooser.dart';

/// Invites [friend] to a game with [onInvite], the invitation of the open
/// «Онлайн». Without it the «Онлайн» that is open invites the friend, and
/// when none is open, «Онлайн» opens and invites the friend: one online
/// screen per game connection.
void inviteFriend(
  BuildContext context,
  LpsUser friend,
  void Function(LpsUser friend)? onInvite,
) {
  if (onInvite != null) return onInvite(friend);

  final home = OnlineHomeHandle.current;
  if (home != null) return home.invite(friend);

  Navigator.push(
    context,
    OnlineGameMasterScreen.createNavigationRoute(
      initialEvent: InvitePressed(friend),
    ),
  );
}

/// The message for an account that could not be fetched, or `null` for the
/// generic connection error.
String? _describeAccountError(
  Translations t,
  AsyncSnapshot<RemoteAccount?> account,
) {
  final error = account.error;
  if (error is AuthorizationException) {
    return authorizationErrorText(t, error);
  }
  // The fetch succeeded, but no account is signed in.
  if (!account.hasError) return t.online.notSignedIn;
  return null;
}

/// The screen of a profile: a header with back and [actions] over [child]
class _ProfileFrame extends StatelessWidget {
  final List<Widget> actions;
  final Widget child;

  const _ProfileFrame({this.actions = const [], required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        D2ScreenHeader(
          onBack: () => Navigator.of(context).maybePop(),
          actions: actions,
        ),
        Expanded(child: child),
      ],
    ),
  );
}

/// Shows user profile independently from already injected providers
class OnlineProfileViewStandalone extends StatefulWidget {
  final int userId;

  const OnlineProfileViewStandalone(this.userId, {super.key});

  @override
  State<OnlineProfileViewStandalone> createState() =>
      _OnlineProfileViewStandaloneState();
}

class _OnlineProfileViewStandaloneState
    extends State<OnlineProfileViewStandalone> {
  final AccountManager _accountManager = GetIt.instance.get<AccountManager>();

  // Kept between builds: a future created in build would fetch the account
  // again on every rebuild.
  late Future<RemoteAccount?> _account = _accountManager
      .getLastSignedInAccount();

  void _reload() => setState(() {
    _account = _accountManager.getLastSignedInAccount();
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D2Colors.of(context).bg,
      body: FutureBuilder<RemoteAccount?>(
        future: _account,
        builder: (context, lastSignedInAccount) {
          if (lastSignedInAccount.connectionState != ConnectionState.done) {
            return _ProfileFrame(
              child: LoadingView(context.t.online.fetchingProfile),
            );
          }
          if (!lastSignedInAccount.hasData) {
            return _ProfileFrame(
              child: ConnectionErrorView(
                onReload: _reload,
                errorMessage: _describeAccountError(
                  context.t,
                  lastSignedInAccount,
                ),
              ),
            );
          }
          return MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RemoteAccount>.value(
                value: lastSignedInAccount.requireData!,
              ),
              RepositoryProvider<ApiRepository>.value(
                value: GetIt.instance.get<ApiRepositoryFactory>().forUser(),
              ),
            ],
            child: OnlineProfileView(userId: widget.userId),
          );
        },
      ),
    );
  }
}

/// Shows user profile
class OnlineProfileView extends StatefulWidget {
  /// Profile owner. If `null` then current authorized user will be used
  final int? userId;

  /// Called when the user invites the shown friend to a game. By default
  /// «Онлайн» opens and invites the friend.
  final void Function(LpsUser friend)? onInvite;

  const OnlineProfileView({this.userId, this.onInvite, super.key});

  @override
  State<OnlineProfileView> createState() => _OnlineProfileViewState();

  /// Creates navigation route for [OnlineProfileView] wrapped in [Scaffold].
  /// [context] must contain [ApiRepository] injected using
  /// [RepositoryProvider] in the widget tree.
  static Route createRoute(
    BuildContext context, {
    int? userId,
    void Function(LpsUser friend)? onInvite,
  }) => MaterialPageRoute(
    builder: (ctx) => Scaffold(
      backgroundColor: D2Colors.of(ctx).bg,
      body: RepositoryProvider.value(
        value: context.read<ApiRepository>(),
        child: OnlineProfileView(userId: userId, onInvite: onInvite),
      ),
    ),
  );
}

enum _ProfileMenu { remove, ban }

class _OnlineProfileViewState extends State<OnlineProfileView> {
  // The cached profile shows an old online status
  bool _shouldUpdate = true;

  // Kept between builds: a refresh rebuilds the view, and a new future would
  // fetch the account again and hide the profile behind a spinner.
  late Future<RemoteAccount?> _account;

  // Lives as long as the view: a bloc created in build was replaced on every
  // refresh, which enabled the buttons again and lost the action's result.
  late final UserActionsBloc _userActionsBloc;

  @override
  void initState() {
    super.initState();
    _account = GetIt.instance.get<AccountManager>().getLastSignedInAccount();
    _userActionsBloc = UserActionsBloc(
      context.read<ApiRepository>(),
      GetIt.instance.get<AchievementsService>(),
    );
  }

  @override
  void dispose() {
    _userActionsBloc.close();
    super.dispose();
  }

  void _reloadAccount() => setState(() {
    _account = GetIt.instance.get<AccountManager>().getLastSignedInAccount();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<RemoteAccount?>(
    future: _account,
    builder: (context, account) {
      if (account.connectionState != ConnectionState.done) {
        return _ProfileFrame(
          child: LoadingView(context.t.online.fetchingProfile),
        );
      }
      if (!account.hasData) {
        return _ProfileFrame(
          child: ConnectionErrorView(
            onReload: _reloadAccount,
            errorMessage: _describeAccountError(context.t, account),
          ),
        );
      }

      final owner = account.requireData!;
      final isOwner = _isOwner(owner);

      return withData<Widget, ApiRepository>(context.watch<ApiRepository>(), (
        repo,
      ) {
        Widget refreshable(Widget child) => RefreshIndicator(
          onRefresh: () => isOwner ? _refreshOwner() : Future.sync(_update),
          child: child,
        );

        if (isOwner) {
          return _ProfileFrame(
            child: refreshable(
              _buildProfileView(
                true,
                context,
                UserProfile(
                  user: owner.user,
                  friendship: Friendship.none,
                  blocked: Blocked.none,
                ),
              ),
            ),
          );
        }

        return FutureBuilder<UserProfile>(
          future: repo.user(widget.userId!, _shouldUpdate),
          builder: (context, snap) {
            if (snap.hasData) {
              _shouldUpdate = false;
              final data = snap.requireData;

              return _ProfileFrame(
                actions: [_buildMenu(data, context)],
                child: refreshable(_buildProfileView(false, context, data)),
              );
            }

            return _ProfileFrame(
              child: refreshable(
                snap.hasError
                    ? showError(context, snap.error!)
                    : showLoadingWidget(context),
              ),
            );
          },
        );
      });
    },
  );

  Widget _buildProfileView(
    bool isOwner,
    BuildContext context,
    UserProfile data,
  ) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      children: [
        _buildTopBlock(isOwner, data, context, t),
        ..._buildActionsBlock(isOwner, data, context, t),
        ..._buildNavigationBlock(isOwner, context, t),
        ..._buildRelatedHistoryBlock(isOwner, context, t),
      ],
    );
  }

  Widget _buildTopBlock(
    bool isOwner,
    UserProfile data,
    BuildContext context,
    Translations t,
  ) {
    final c = D2Colors.of(context);
    final user = data.user;

    return Row(
      children: [
        InkWell(
          onTap: isOwner
              ? () => showD2Sheet<void>(
                  context,
                  builder: (_) => AvatarChooserView(
                    context.read<ApiRepository>(),
                    onAvatarUpdated: _reloadAccount,
                  ),
                )
              : null,
          child: Transform.rotate(
            angle: -3 * math.pi / 180,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow.withValues(alpha: 0.22),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: lpsUserAvatar(context, user, size: 58),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: D2Text.title.copyWith(fontSize: 20, color: c.ink),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'ID ${user.id}',
                    style: D2Text.caption.copyWith(color: c.inkSoft),
                  ),
                  _showOnlineStatus(isOwner, t, user),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The «⋮» menu of the header
  Widget _buildMenu(UserProfile data, BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final user = data.user;
    final canRemove =
        data.friendship == Friendship.friends && !data.blocked.isBlockingMe;

    // The blocked user has no menu: «Разблокировать» is on the card
    if (data.blocked.isBlockedByMe) return const SizedBox.shrink();

    return BlocBuilder<UserActionsBloc, UserActionsState>(
      bloc: _userActionsBloc,
      builder: (context, state) => PopupMenuButton<_ProfileMenu>(
        enabled: state is! UserProcessingActionState,
        tooltip: user.name,
        icon: D2Icon(D2Glyph.more, size: 22, color: c.ink),
        onSelected: (item) => _userActionsBloc.add(switch (item) {
          _ProfileMenu.remove => UserEvent(
            user,
            UserUserAction.removeFromFriends,
          ),
          _ProfileMenu.ban => UserEvent(
            user,
            UserUserAction.banUser,
            confirmationMessage: t.online.userBanned,
          ),
        }),
        itemBuilder: (_) => [
          if (canRemove)
            PopupMenuItem(
              value: _ProfileMenu.remove,
              child: Text(t.online.removeFromFriends, style: D2Text.body),
            ),
          PopupMenuItem(
            value: _ProfileMenu.ban,
            child: Text(
              t.online.ban,
              style: D2Text.body.copyWith(color: c.error),
            ),
          ),
        ],
      ),
    );
  }

  Iterable<Widget> _buildActionsBlock(
    bool isOwner,
    UserProfile data,
    BuildContext context,
    Translations t,
  ) sync* {
    if (isOwner) return;

    final userActionsBloc = _userActionsBloc;

    yield const SizedBox(height: 20);
    yield BlocConsumer<UserActionsBloc, UserActionsState>(
      bloc: userActionsBloc,
      builder: (context, state) {
        if (state is UserActionErrorState) {
          return showError(context, state.error);
        }

        return _buildAction(
          data,
          context,
          userActionsBloc,
          t,
          state is UserProcessingActionState,
        );
      },
      listener: (context, state) {
        if (state is UserActionConfirmationState) {
          showUndoSnackbar(
            context,
            state.sourceEvent.confirmationMessage!,
            onComplete: () => userActionsBloc.add(
              UserActionConfirmedEvent(state.sourceEvent),
            ),
          );
        } else if (state is UserActionDoneState) {
          final message = state.sourceEvent.confirmationMessage;
          if (message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                duration: const Duration(seconds: 3),
                content: Text(state.sourceEvent.confirmationMessage!),
              ),
            );
          }
          // The repository dropped the profile the action changed
          _update(force: false);
        }
      },
    );
  }

  /// The action of the profile by [UserProfile.friendship] and
  /// [UserProfile.blocked]. Nobody can be invited or asked to be a friend
  /// while either user blocks the other.
  Widget _buildAction(
    UserProfile data,
    BuildContext context,
    UserActionsBloc bloc,
    Translations t,
    bool disabled,
  ) {
    final c = D2Colors.of(context);
    final user = data.user;

    VoidCallback? act(UserEvent event) =>
        disabled ? null : () => bloc.add(event);

    Widget blockedMe() => Row(
      children: [
        D2Icon(D2Glyph.ban, size: 20, color: c.error),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t.online.inputBan,
            style: D2Text.bodyRegular.copyWith(
              fontWeight: FontWeight.w500,
              fontVariations: const [FontVariation('wght', 500)],
              color: c.error,
            ),
          ),
        ),
      ],
    );

    if (data.blocked.isBlockedByMe) {
      final card = D2Card(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                D2Icon(D2Glyph.ban, size: 20, color: c.ink),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.online.inYourBlacklist,
                    style: D2Text.bodyRegular.copyWith(
                      fontWeight: FontWeight.w500,
                      fontVariations: const [FontVariation('wght', 500)],
                      color: c.ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            D2Button(
              label: t.online.unban,
              kind: D2ButtonKind.tonal,
              expand: true,
              onPressed: act(
                UserEvent(
                  user,
                  UserUserAction.unbanUser,
                  confirmationMessage: t.online.userUnbanned,
                ),
              ),
            ),
          ],
        ),
      );

      if (!data.blocked.isBlockingMe) return card;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [blockedMe(), const SizedBox(height: 12), card],
      );
    }

    if (data.blocked.isBlockingMe) return blockedMe();

    switch (data.friendship) {
      case Friendship.friends:
        return D2Button(
          label: t.online.invite,
          icon: D2Glyph.play,
          kind: D2ButtonKind.accent,
          size: D2ButtonSize.large,
          expand: true,
          onPressed: disabled
              ? null
              : () => inviteFriend(context, user, widget.onInvite),
        );
      case Friendship.none:
        return D2Button(
          label: t.online.addToFriend,
          icon: D2Glyph.userPlus,
          kind: D2ButtonKind.accent,
          size: D2ButtonSize.large,
          expand: true,
          onPressed: act(UserEvent(user, UserUserAction.addToFriends)),
        );
      case Friendship.outgoing:
        return D2Card(
          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.online.requestSent,
                  style: D2Text.bodyRegular.copyWith(
                    fontWeight: FontWeight.w500,
                    fontVariations: const [FontVariation('wght', 500)],
                    color: c.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              D2Button(
                label: t.online.cancelInvite,
                kind: D2ButtonKind.tonal,
                onPressed: act(UserEvent(user, UserUserAction.cancelRequest)),
              ),
            ],
          ),
        );
      case Friendship.incoming:
        return D2Card(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.online.wantsFriendship,
                style: D2Text.bodyRegular.copyWith(
                  fontWeight: FontWeight.w500,
                  fontVariations: const [FontVariation('wght', 500)],
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: D2Button(
                      label: t.decline,
                      kind: D2ButtonKind.tonal,
                      expand: true,
                      onPressed: act(
                        UserEvent(user, UserUserAction.declineRequest),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: D2Button(
                      label: t.accept,
                      kind: D2ButtonKind.accent,
                      expand: true,
                      onPressed: act(
                        UserEvent(user, UserUserAction.acceptRequest),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
    }
  }

  Iterable<Widget> _buildNavigationBlock(
    bool isOwner,
    BuildContext context,
    Translations t,
  ) sync* {
    if (!isOwner) return;
    yield const SizedBox(height: 20);
    yield D2Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildNavigationButton(
            D2Glyph.friends,
            t.online.friendsTab,
            () => OnlineFriendsScreen(onInvite: widget.onInvite),
          ),
          _buildNavigationButton(
            D2Glyph.history,
            t.online.historyTab,
            () => OnlineHistoryScreen(onInvite: widget.onInvite),
          ),
          _buildNavigationButton(
            D2Glyph.ban,
            t.online.blacklistTab,
            () => OnlineBanlistScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(
    D2Glyph icon,
    String label,
    Widget Function() destinationScreen,
  ) {
    final c = D2Colors.of(context);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => MultiRepositoryProvider(
            providers: [
              RepositoryProvider.value(value: context.read<ApiRepository>()),
            ],
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    D2ScreenHeader(
                      title: label,
                      onBack: () => Navigator.maybePop(ctx),
                    ),
                    Expanded(child: destinationScreen()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              D2Icon(icon, size: 22, color: c.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: D2Text.body.copyWith(color: c.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showOnlineStatus(bool isOwner, Translations t, LpsUser user) {
    final c = D2Colors.of(context);
    final now = DateTime.now();
    final online = isOwner || user.isOnline(now);

    return online
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: c.mint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                t.online.lastSeen.now,
                style: D2Text.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  fontVariations: const [FontVariation('wght', 500)],
                  color: c.ink,
                ),
              ),
            ],
          )
        : Text(
            formatLastSeen(t, user.lastSeenAt, now),
            style: D2Text.caption.copyWith(color: c.inkSoft),
          );
  }

  Iterable<Widget> _buildRelatedHistoryBlock(
    bool isOwner,
    BuildContext context,
    Translations t,
  ) sync* {
    if (isOwner) return;
    yield const SizedBox(height: 20);
    yield OnlineHistoryScreen(
      withUser: widget.userId,
      embedded: true,
      embeddedTitle: t.online.battleHistory,
      onInvite: widget.onInvite,
    );
  }

  /// Asks the server for the own account again
  Future<void> _refreshOwner() {
    GetIt.instance.get<AccountManager>().invalidate();
    _reloadAccount();

    return _account;
  }

  void _update({bool force = true}) {
    // The error of the last action replaces the buttons until a refresh.
    if (_userActionsBloc.state is UserActionErrorState) {
      _userActionsBloc.add(const UserActionsResetEvent());
    }
    setState(() {
      _shouldUpdate = force;
    });
  }

  bool _isOwner(RemoteAccount account) =>
      widget.userId == null || widget.userId == account.userId;
}
