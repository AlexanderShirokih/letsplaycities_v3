import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:lets_play_cities/base/achievements/achievements_service.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/banlist.dart';
import 'package:lets_play_cities/screens/online/common_online_widgets.dart';
import 'package:lets_play_cities/screens/online/friends.dart';
import 'package:lets_play_cities/screens/online/game_waiting_room_screen.dart';
import 'package:lets_play_cities/screens/online/history.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';

import 'avatars/avatar_chooser.dart';

final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
final DateFormat _timeFormat = DateFormat('HH:mm');

/// Describes when a user was last online, as seen at [now]: the time for
/// today, "yesterday" and the time for the day before, the date otherwise.
@visibleForTesting
String formatLastVisit(Translations t, DateTime date, DateTime now) {
  // Compares calendar dates; UTC keeps a daylight saving change from making
  // a day shorter than 24 hours.
  final daysAgo = DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime.utc(date.year, date.month, date.day)).inDays;

  switch (daysAgo) {
    case 0:
      return t.online.lastOnline(date: _timeFormat.format(date));
    case 1:
      return t.online.lastOnline(
        date: t.online.yesterday(time: _timeFormat.format(date)),
      );
    default:
      return t.online.lastOnline(date: _dateFormat.format(date));
  }
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

/// Shows user profile independently from already injected providers
class OnlineProfileViewStandalone extends StatefulWidget {
  final BaseProfileInfo target;

  const OnlineProfileViewStandalone(this.target, {super.key});

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
    return RepositoryProvider<AccountManager>.value(
      value: _accountManager,
      child: FutureBuilder<RemoteAccount?>(
        future: _account,
        builder: (context, lastSignedInAccount) {
          if (lastSignedInAccount.connectionState != ConnectionState.done) {
            return LoadingView(context.t.online.fetchingProfile);
          }
          if (!lastSignedInAccount.hasData) {
            return ConnectionErrorView(
              onReload: _reload,
              errorMessage: _describeAccountError(
                context.t,
                lastSignedInAccount,
              ),
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
                  value: GetIt.instance
                      .get<ApiRepositoryFactory>()
                      .forCredential(
                        lastSignedInAccount.requireData!.credential,
                      ),
                ),
              ],
              child: OnlineProfileView(target: widget.target),
            ),
          );
        },
      ),
    );
  }
}

/// Shows user profile
class OnlineProfileView extends StatefulWidget {
  /// Profile owner. If `null` then current authorized user will be used
  final BaseProfileInfo? target;

  const OnlineProfileView({this.target, super.key});

  @override
  State<OnlineProfileView> createState() => _OnlineProfileViewState();

  /// Creates navigation route for [OnlineProfileView] wrapped in [Scaffold].
  /// [context] must contain [ApiRepository] and [AccountManager] injected
  /// using [RepositoryProvider] in the widget tree.
  static Route createRoute(BuildContext context, {BaseProfileInfo? target}) =>
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: Text(ctx.t.online.profileTab)),
          body: MultiRepositoryProvider(
            providers: [
              RepositoryProvider.value(value: context.read<ApiRepository>()),
              RepositoryProvider.value(value: context.read<AccountManager>()),
            ],
            child: OnlineProfileView(target: target),
          ),
        ),
      );
}

class _OnlineProfileViewState extends State<OnlineProfileView>
    with NetworkAvatarBuildingMixin {
  bool _shouldUpdate = false;

  // Kept between builds: a refresh rebuilds the view, and a new future would
  // fetch the account again and hide the profile behind a spinner.
  late Future<RemoteAccount?> _account;

  // Lives as long as the view: a bloc created in build was replaced on every
  // refresh, which enabled the buttons again and lost the action's result.
  late final UserActionsBloc _userActionsBloc;

  @override
  void initState() {
    super.initState();
    _account = context.read<AccountManager>().getLastSignedInAccount();
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
    _account = context.read<AccountManager>().getLastSignedInAccount();
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
          showAppBar: false,
        );
      }

      return withData<Widget, ApiRepository>(
        context.watch<ApiRepository>(),
        (repo) => RefreshIndicator(
          onRefresh: () async => _update(),
          child: Stack(
            children: [
              Positioned.fill(
                child: FutureBuilder<ProfileInfo>(
                  future: repo.getProfileInfo(
                    widget.target ?? account.requireData!.baseProfileInfo,
                    _shouldUpdate,
                  ),
                  builder: (context, snap) {
                    if (snap.hasData) {
                      _shouldUpdate = false;
                      return _buildProfileView(
                        snap.requireData.friendshipStatus ==
                            FriendshipStatus.owner,
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
              if (_isOwner(account.requireData!))
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, right: 24.0),
                    child: FloatingActionButton.extended(
                      onPressed: () =>
                          context.read<AccountManager>().signOut().then((_) {
                            if (context.mounted) Navigator.of(context).pop();
                          }),
                      icon: FaIcon(FontAwesomeIcons.rightFromBracket),
                      label: Text(context.t.online.signOut),
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
    ProfileInfo data,
  ) {
    final t = context.t;
    return ListView(
      children: [
        ..._buildTopBlock(isOwner, data, context, t),
        ..._buildIdBlock(data, context),
        ..._buildActionsBlock(isOwner, data, context, t),
        ..._buildNavigationBlock(isOwner, data, context, t),
        ..._buildRelatedHistoryBlock(isOwner, data, context, t),
      ],
    );
  }

  Iterable<Widget> _buildTopBlock(
    bool isOwner,
    ProfileInfo data,
    BuildContext context,
    Translations t,
  ) sync* {
    yield Container(
      padding: EdgeInsets.all(28.0),
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
                      onAvatarUpdated: () => _update(),
                    ),
                  )
                : null,
            child: buildAvatar(data, 60.0),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(left: 28.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.login,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.clip,
                  ),
                  const SizedBox(height: 12.0),
                  _showOnlineStatus(isOwner, t, data),
                  ..._showRole(t, data),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildActionsBlock(
    bool isOwner,
    ProfileInfo data,
    BuildContext context,
    Translations t,
  ) sync* {
    if (isOwner) return;

    if (data.banStatus == BanStatus.inputBan) {
      yield Container(
        alignment: Alignment.center,
        child: Text(
          t.online.inputBan,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 16.0,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
      yield const Divider(height: 18.0, thickness: 1.0);
      return;
    }

    final userActionsBloc = _userActionsBloc;

    yield BlocConsumer<UserActionsBloc, UserActionsState>(
      bloc: userActionsBloc,
      builder: (context, state) {
        if (state is UserActionErrorState) {
          return showError(context, state.error);
        }
        final isProcessing = state is UserProcessingActionState;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _getFriendshipButton(
              data,
              context,
              userActionsBloc,
              t,
              isProcessing,
            ),
            _getFriendRequestButton(
              data,
              context,
              userActionsBloc,
              t,
              isProcessing,
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
          _update();
        }
      },
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildIdBlock(ProfileInfo data, BuildContext context) sync* {
    yield Container(
      alignment: Alignment.center,
      child: Text(
        'ID ${data.userId}',
        style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 16.0),
      ),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Iterable<Widget> _buildNavigationBlock(
    bool isOwner,
    ProfileInfo data,
    BuildContext context,
    Translations t,
  ) sync* {
    if (!isOwner) return;
    yield _buildNavigationButton(
      FaIcon(FontAwesomeIcons.userGroup),
      t.online.friendsTab,
      () => OnlineFriendsScreen(),
    );
    yield _buildNavigationButton(
      FaIcon(FontAwesomeIcons.clockRotateLeft),
      t.online.historyTab,
      () => OnlineHistoryScreen(target: data),
    );
    yield _buildNavigationButton(
      FaIcon(FontAwesomeIcons.userSlash),
      t.online.blacklistTab,
      () => OnlineBanlistScreen(),
    );
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  Widget _buildNavigationButton(
    Widget icon,
    String label,
    Widget Function() destinationScreen,
  ) => ListTile(
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(value: context.read<ApiRepository>()),
            RepositoryProvider.value(value: context.read<AccountManager>()),
          ],
          child: Scaffold(
            appBar: AppBar(title: Text(label)),
            body: destinationScreen(),
          ),
        ),
      ),
    ),
    leading: icon,
    title: Text(label),
  );

  Widget _createButton(String label, VoidCallback? onPressed) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
      shape: _createRoundedBorder(),
      backgroundColor: Theme.of(context).primaryColor,
    ),
    onPressed: onPressed,
    child: Text(label),
  );

  Widget _getFriendshipButton(
    ProfileInfo data,
    BuildContext context,
    UserActionsBloc bloc,
    Translations t,
    bool disabled,
  ) {
    switch (data.friendshipStatus) {
      case FriendshipStatus.notFriends:
        return _createButton(
          t.online.addToFriend,
          disabled
              ? null
              : () => bloc.add(UserEvent(data, UserUserAction.addToFriends)),
        );
      case FriendshipStatus.friends:
        return _createButton(
          t.online.removeFromFriends,
          disabled
              ? null
              : () =>
                    bloc.add(UserEvent(data, UserUserAction.removeFromFriends)),
        );

      case FriendshipStatus.inputRequest:
        return _createButton(
          t.online.cancelFriendshipRequest,
          disabled
              ? null
              : () => bloc.add(UserEvent(data, UserUserAction.cancelRequest)),
        );
      case FriendshipStatus.outputRequest:
        return _AcceptOrDeclineButton(
          t,
          onResult: disabled
              ? null
              : (isAccepted) => bloc.add(
                  UserEvent(
                    data,
                    isAccepted
                        ? UserUserAction.acceptRequest
                        : UserUserAction.declineRequest,
                  ),
                ),
        );
      default:
        throw ('Can\'t show friendship button for itself');
    }
  }

  Widget _getFriendRequestButton(
    ProfileInfo data,
    BuildContext context,
    UserActionsBloc bloc,
    Translations t,
    bool disabled,
  ) {
    switch (data.banStatus) {
      case BanStatus.outputBan:
        return _createButton(
          t.online.unban,
          disabled
              ? null
              : () => bloc.add(
                  UserEvent(
                    data,
                    UserUserAction.unbanUser,
                    confirmationMessage: t.online.userUnbanned,
                  ),
                ),
        );
      case BanStatus.notBanned:
        return data.friendshipStatus == FriendshipStatus.friends
            ? _createButton(
                t.online.invite,
                disabled
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RepositoryProvider.value(
                            value: context.read<AccountManager>(),
                            child: GameWaitingRoomScreenStandalone(
                              request: FriendGameRequest(
                                mode: FriendGameRequestType.invite,
                                target: data,
                              ),
                            ),
                          ),
                        ),
                      ),
              )
            : _createButton(
                t.online.ban,
                disabled
                    ? null
                    : () => bloc.add(
                        UserEvent(
                          data,
                          UserUserAction.banUser,
                          confirmationMessage: t.online.userBanned,
                        ),
                      ),
              );
      default:
        return Container();
    }
  }

  RoundedRectangleBorder _createRoundedBorder() => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12.0),
    side: BorderSide.none,
  );

  Iterable<Widget> _showRole(Translations t, ProfileInfo data) sync* {
    switch (data.role) {
      case Role.banned:
        yield const SizedBox(height: 10.0);
        yield Text(t.online.banned);
        break;
      case Role.admin:
        yield const SizedBox(height: 10.0);
        yield Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.userLock),
            const SizedBox(width: 8.0),
            Text(t.online.admin),
          ],
        );
        break;
      case Role.regular:
        break;
    }
  }

  Widget _showOnlineStatus(bool isOwner, Translations t, ProfileInfo data) {
    bool isOnline(ProfileInfo info) =>
        DateTime.now().difference(info.lastVisitDate) < Duration(minutes: 10) ||
        isOwner;

    return (isOnline(data))
        ? Row(
            children: [
              FaIcon(
                FontAwesomeIcons.solidCircle,
                color: Colors.green,
                size: 12.0,
              ),
              const SizedBox(width: 6.0),
              Text(t.online.title),
            ],
          )
        : Text(
            formatLastVisit(t, data.lastVisitDate, DateTime.now()),
            style: Theme.of(context).textTheme.bodyMedium!
                .copyWith(fontStyle: FontStyle.italic),
          );
  }

  Iterable<Widget> _buildRelatedHistoryBlock(
    bool isOwner,
    ProfileInfo data,
    BuildContext context,
    Translations t,
  ) sync* {
    if (isOwner) return;
    yield Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        t.online.battleHistory,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
    yield OnlineHistoryScreen(target: widget.target, embedded: true);
    yield const Divider(height: 18.0, thickness: 1.0);
  }

  void _update() {
    // The error of the last action replaces the buttons until a refresh.
    if (_userActionsBloc.state is UserActionErrorState) {
      _userActionsBloc.add(const UserActionsResetEvent());
    }
    setState(() {
      _shouldUpdate = true;
    });
  }

  bool _isOwner(RemoteAccount account) =>
      widget.target == null ||
      widget.target!.userId == account.credential.userId;
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
      color: Theme.of(context).primaryColor,
    ),
    child: DropdownButton(
      value: _selected,
      elevation: 5,
      items: widget.onResult == null
          ? null
          : [0, 1]
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      _values[e],
                      style: Theme.of(context).textTheme.bodyLarge,
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
