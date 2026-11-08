import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
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

import 'avatars/avatar_chooser.dart';

/// Invites [friend] to a game with [onInvite], the invitation of the open
/// «Онлайн». Without it «Онлайн» opens and invites the friend over the same
/// game connection.
void inviteFriend(
  BuildContext context,
  LpsUser friend,
  void Function(LpsUser friend)? onInvite,
) {
  if (onInvite != null) return onInvite(friend);

  Navigator.push(
    context,
    OnlineGameMasterScreen.createNavigationRoute(invite: friend),
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

Widget _divider(BuildContext context) =>
    Divider(height: 18.0, thickness: 1.0, color: D2Colors.of(context).edge);

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
    return FutureBuilder<RemoteAccount?>(
      future: _account,
      builder: (context, lastSignedInAccount) {
        if (lastSignedInAccount.connectionState != ConnectionState.done) {
          return LoadingView(context.t.online.fetchingProfile);
        }
        if (!lastSignedInAccount.hasData) {
          return ConnectionErrorView(
            onReload: _reload,
            errorMessage: _describeAccountError(context.t, lastSignedInAccount),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(context.t.online.profileTab)),
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RemoteAccount>.value(
                value: lastSignedInAccount.requireData!,
              ),
              // Inside a LAN game's GetIt scope this is the factory for
              // the LAN server.
              RepositoryProvider<ApiRepository>.value(
                value: GetIt.instance.get<ApiRepositoryFactory>().forUser(),
              ),
            ],
            child: OnlineProfileView(userId: widget.userId),
          ),
        );
      },
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
      appBar: AppBar(title: Text(ctx.t.online.profileTab)),
      body: RepositoryProvider.value(
        value: context.read<ApiRepository>(),
        child: OnlineProfileView(userId: userId, onInvite: onInvite),
      ),
    ),
  );
}

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
        return LoadingView('...');
      }
      if (!account.hasData) {
        return ConnectionErrorView(
          onReload: _reloadAccount,
          errorMessage: _describeAccountError(context.t, account),
        );
      }

      final owner = account.requireData!;
      final isOwner = _isOwner(owner);

      return withData<Widget, ApiRepository>(
        context.watch<ApiRepository>(),
        (repo) => RefreshIndicator(
          onRefresh: () => isOwner ? _refreshOwner() : Future.sync(_update),
          child: Stack(
            children: [
              Positioned.fill(
                child: isOwner
                    ? _buildProfileView(
                        true,
                        context,
                        UserProfile(
                          user: owner.user,
                          friendship: Friendship.none,
                          blocked: Blocked.none,
                        ),
                      )
                    : FutureBuilder<UserProfile>(
                        future: repo.user(widget.userId!, _shouldUpdate),
                        builder: (context, snap) {
                          if (snap.hasData) {
                            _shouldUpdate = false;
                            return _buildProfileView(
                              false,
                              context,
                              snap.requireData,
                            );
                          } else if (snap.hasError) {
                            return showError(context, snap.error!);
                          } else {
                            return showLoadingWidget(context);
                          }
                        },
                      ),
              ),
              if (isOwner)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, right: 24.0),
                    child: FloatingActionButton.extended(
                      backgroundColor: D2Colors.of(context).orange,
                      foregroundColor: D2Colors.of(context).shadow,
                      onPressed: () => GetIt.instance
                          .get<AccountManager>()
                          .signOut()
                          .then((_) {
                            if (context.mounted) Navigator.of(context).pop();
                          }),
                      icon: const D2Icon(D2Glyph.exit),
                      label: Text(context.t.online.signOut, style: D2Text.body),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget _buildProfileView(
    bool isOwner,
    BuildContext context,
    UserProfile data,
  ) {
    final t = context.t;
    return ListView(
      padding: const EdgeInsets.only(bottom: 88.0),
      children: [
        ..._buildTopBlock(isOwner, data, context, t),
        ..._buildIdBlock(data, context),
        ..._buildActionsBlock(isOwner, data, context, t),
        ..._buildNavigationBlock(isOwner, context, t),
        ..._buildRelatedHistoryBlock(isOwner, context, t),
      ],
    );
  }

  Iterable<Widget> _buildTopBlock(
    bool isOwner,
    UserProfile data,
    BuildContext context,
    Translations t,
  ) sync* {
    final c = D2Colors.of(context);
    final user = data.user;
    yield Container(
      padding: EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: isOwner
                ? () => showModalBottomSheet(
                    context: context,
                    builder: (_) => AvatarChooserView(
                      context.read<ApiRepository>(),
                      onAvatarUpdated: _reloadAccount,
                    ),
                  )
                : null,
            child: lpsUserAvatar(context, user, size: 72.0),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: D2Text.title.copyWith(color: c.ink),
                    overflow: TextOverflow.clip,
                  ),
                  const SizedBox(height: 12.0),
                  _showOnlineStatus(isOwner, t, user),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    yield _divider(context);
  }

  Iterable<Widget> _buildActionsBlock(
    bool isOwner,
    UserProfile data,
    BuildContext context,
    Translations t,
  ) sync* {
    if (isOwner) return;

    final userActionsBloc = _userActionsBloc;

    yield BlocConsumer<UserActionsBloc, UserActionsState>(
      bloc: userActionsBloc,
      builder: (context, state) {
        if (state is UserActionErrorState) {
          return showError(context, state.error);
        }
        final isProcessing = state is UserProcessingActionState;
        return Column(
          children: [
            if (data.blocked.isBlockingMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  t.online.inputBan,
                  style: D2Text.body.copyWith(
                    color: D2Colors.of(context).error,
                  ),
                ),
              ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12.0,
              runSpacing: 12.0,
              children: _actionButtons(
                data,
                context,
                userActionsBloc,
                t,
                isProcessing,
              ),
            ),
          ],
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
    yield _divider(context);
  }

  /// The buttons of the profile by [UserProfile.friendship] and
  /// [UserProfile.blocked]. Nobody can be invited or asked to be a friend
  /// while either user blocks the other.
  List<Widget> _actionButtons(
    UserProfile data,
    BuildContext context,
    UserActionsBloc bloc,
    Translations t,
    bool disabled,
  ) {
    final user = data.user;

    Widget unblock() => _createButton(
      t.online.unban,
      disabled
          ? null
          : () => bloc.add(
              UserEvent(
                user,
                UserUserAction.unbanUser,
                confirmationMessage: t.online.userUnbanned,
              ),
            ),
    );

    if (data.blocked.isBlockedByMe) return [unblock()];
    if (data.blocked.isBlockingMe) return const [];

    return [
      _getFriendshipButton(data, bloc, t, disabled),
      if (data.friendship == Friendship.friends)
        _createButton(
          t.online.invite,
          disabled ? null : () => inviteFriend(context, user, widget.onInvite),
        )
      else
        _createButton(
          t.online.ban,
          disabled
              ? null
              : () => bloc.add(
                  UserEvent(
                    user,
                    UserUserAction.banUser,
                    confirmationMessage: t.online.userBanned,
                  ),
                ),
        ),
    ];
  }

  Iterable<Widget> _buildIdBlock(UserProfile data, BuildContext context) sync* {
    yield Container(
      alignment: Alignment.center,
      child: Text(
        'ID ${data.user.id}',
        style: D2Text.body.copyWith(color: D2Colors.of(context).inkSoft),
      ),
    );
    yield _divider(context);
  }

  Iterable<Widget> _buildNavigationBlock(
    bool isOwner,
    BuildContext context,
    Translations t,
  ) sync* {
    if (!isOwner) return;
    yield _buildNavigationButton(
      D2Glyph.friends,
      t.online.friendsTab,
      () => OnlineFriendsScreen(onInvite: widget.onInvite),
    );
    yield _buildNavigationButton(
      D2Glyph.history,
      t.online.historyTab,
      () => OnlineHistoryScreen(),
    );
    yield _buildNavigationButton(
      D2Glyph.ban,
      t.online.blacklistTab,
      () => OnlineBanlistScreen(),
    );
    yield _divider(context);
  }

  Widget _buildNavigationButton(
    D2Glyph icon,
    String label,
    Widget Function() destinationScreen,
  ) => ListTile(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: context.read<ApiRepository>()),
          ],
          child: Scaffold(
            appBar: AppBar(title: Text(label)),
            body: destinationScreen(),
          ),
        ),
      ),
    ),
    leading: D2Icon(icon),
    title: Text(label, style: D2Text.body),
  );

  Widget _createButton(String label, VoidCallback? onPressed) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
      shape: _createRoundedBorder(),
      backgroundColor: D2Colors.of(context).violet,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      textStyle: D2Text.body,
    ),
    onPressed: onPressed,
    child: Text(label),
  );

  Widget _getFriendshipButton(
    UserProfile data,
    UserActionsBloc bloc,
    Translations t,
    bool disabled,
  ) {
    final user = data.user;

    switch (data.friendship) {
      case Friendship.none:
        return _createButton(
          t.online.addToFriend,
          disabled
              ? null
              : () => bloc.add(UserEvent(user, UserUserAction.addToFriends)),
        );
      case Friendship.friends:
        return _createButton(
          t.online.removeFromFriends,
          disabled
              ? null
              : () =>
                    bloc.add(UserEvent(user, UserUserAction.removeFromFriends)),
        );
      case Friendship.outgoing:
        return _createButton(
          t.online.cancelFriendshipRequest,
          disabled
              ? null
              : () => bloc.add(UserEvent(user, UserUserAction.cancelRequest)),
        );
      case Friendship.incoming:
        return _AcceptOrDeclineButton(
          t,
          onResult: disabled
              ? null
              : (isAccepted) => bloc.add(
                  UserEvent(
                    user,
                    isAccepted
                        ? UserUserAction.acceptRequest
                        : UserUserAction.declineRequest,
                  ),
                ),
        );
    }
  }

  RoundedRectangleBorder _createRoundedBorder() => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12.0),
    side: BorderSide.none,
  );

  Widget _showOnlineStatus(bool isOwner, Translations t, LpsUser user) {
    final now = DateTime.now();
    final online = isOwner || user.isOnline(now);

    return online
        ? Row(
            children: [
              Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: D2Colors.of(context).mint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6.0),
              Text(t.online.lastSeen.now, style: D2Text.bodyRegular),
            ],
          )
        : Text(
            formatLastSeen(t, user.lastSeenAt, now),
            style: D2Text.bodyRegular.copyWith(
              color: D2Colors.of(context).inkSoft,
            ),
          );
  }

  Iterable<Widget> _buildRelatedHistoryBlock(
    bool isOwner,
    BuildContext context,
    Translations t,
  ) sync* {
    if (isOwner) return;
    yield Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        t.online.battleHistory,
        style: D2Text.section.copyWith(color: D2Colors.of(context).ink),
      ),
    );
    yield OnlineHistoryScreen(withUser: widget.userId, embedded: true);
    yield _divider(context);
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

class _AcceptOrDeclineButton extends StatefulWidget {
  final Translations t;
  final void Function(bool)? onResult;

  const _AcceptOrDeclineButton(this.t, {required this.onResult});

  @override
  State<_AcceptOrDeclineButton> createState() => __AcceptOrDeclineButtonState();
}

class __AcceptOrDeclineButtonState extends State<_AcceptOrDeclineButton> {
  late final List<String> _values;

  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _values = [
      widget.t.online.acceptFriendshipRequest,
      widget.t.online.declineFriendshipRequest,
    ];
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(left: 10.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12.0),
      color: D2Colors.of(context).violet,
    ),
    child: DropdownButton(
      value: _selected,
      elevation: 5,
      dropdownColor: D2Colors.of(context).violet,
      iconEnabledColor: Theme.of(context).colorScheme.onPrimary,
      items: widget.onResult == null
          ? null
          : [0, 1]
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      _values[e],
                      style: D2Text.body.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
      onChanged: (int? newValue) => setState(() {
        _selected = newValue ?? 0;
        widget.onResult!(_selected == 0);
      }),
    ),
  );
}
