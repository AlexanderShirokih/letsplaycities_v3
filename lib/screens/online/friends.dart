import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/i18n/last_seen.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/remote/model/social.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'base_list_fetching_screen_mixin.dart';
import 'common_online_widgets.dart';

/// Friends list screen
/// Provides a list of user friends and the way to remove friends,
/// accept or decline friend requests
class OnlineFriendsScreen extends StatelessWidget
    with BaseListFetchingScreenMixin<FriendEntry> {
  /// Called when the user invites an online friend to a game
  final void Function(LpsUser friend)? onInvite;

  const OnlineFriendsScreen({super.key, this.onInvite});

  @override
  UserFetchType get fetchEvent => UserFetchType.getFriendsList;

  // The cached online status of the friends is old after a while
  @override
  bool get refreshOnOpen => true;

  @override
  Widget buildItem(BuildContext context, FriendEntry data) =>
      throw UnimplementedError('The friends are built by buildBody');

  @override
  Widget buildBody(
    BuildContext context,
    List<FriendEntry> data,
    bool hasMore,
    Object? moreError,
  ) => _FriendsBody(entries: data, onInvite: onInvite);

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => Text(
    context.t.online.noFriendsPlaceholder,
    textAlign: TextAlign.center,
    style: withData<TextStyle, TextTheme>(
      Theme.of(context).textTheme,
      (textTheme) =>
          textTheme.headlineSmall!.copyWith(color: textTheme.bodySmall!.color),
    ),
  );
}

class _FriendsBody extends StatefulWidget {
  final List<FriendEntry> entries;
  final void Function(LpsUser friend)? onInvite;

  const _FriendsBody({required this.entries, required this.onInvite});

  @override
  State<_FriendsBody> createState() => _FriendsBodyState();
}

class _FriendsBodyState extends State<_FriendsBody> {
  String _query = '';

  bool _matches(FriendEntry entry) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;

    return entry.user.name.toLowerCase().contains(query) ||
        entry.user.id.toString() == query;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final found = widget.entries.where(_matches).toList();
    final friendCount = widget.entries
        .where((e) => e.status == FriendStatus.friends)
        .length;
    final requests = [
      for (final e in found)
        if (e.status != FriendStatus.friends) e,
    ];
    final friends = [
      for (final e in found)
        if (e.status == FriendStatus.friends) e,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      children: [
        _SearchField(onChanged: (value) => setState(() => _query = value)),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            t.online.friendRequests,
            style: D2Text.section.copyWith(color: c.ink),
          ),
          const SizedBox(height: 8),
          for (final request in requests) ...[
            _RequestCard(entry: request, onInvite: widget.onInvite),
            const SizedBox(height: 8),
          ],
        ],
        if (friendCount > 0) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                t.online.myFriends,
                style: D2Text.section.copyWith(color: c.ink),
              ),
              const SizedBox(width: 8),
              Text(
                '$friendCount',
                style: D2Text.body.copyWith(color: c.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (friends.isNotEmpty)
            D2Card(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < friends.length; i++) ...[
                    if (i > 0) Container(height: 2, color: c.bg),
                    _FriendRow(
                      user: friends[i].user,
                      onInvite: widget.onInvite,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return D2Card(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          D2Icon(D2Glyph.search, size: 22, color: c.inkSoft),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: D2Text.bodyRegular.copyWith(fontSize: 16, color: c.ink),
              decoration: InputDecoration(
                hintText: context.t.online.searchHint,
                hintStyle: D2Text.bodyRegular.copyWith(
                  fontSize: 16,
                  color: c.inkSoft,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An incoming request with "accept" and "decline", or an outgoing one
/// with "cancel"
class _RequestCard extends StatelessWidget {
  final FriendEntry entry;

  /// Passed to the profile, which can invite once the request is accepted
  final void Function(LpsUser friend)? onInvite;

  const _RequestCard({required this.entry, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final user = entry.user;
    final incoming = entry.status == FriendStatus.incoming;
    final bloc = context.read<UserActionsBloc>();

    return D2Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              OnlineProfileView.createRoute(
                context,
                userId: user.id,
                onInvite: onInvite,
              ),
            ),
            child: Row(
              children: [
                lpsUserAvatar(context, user),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: D2Text.body.copyWith(color: c.ink),
                      ),
                      Text(
                        incoming ? 'ID ${user.id}' : t.online.requestSent,
                        style: D2Text.caption.copyWith(color: c.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (incoming)
            Row(
              children: [
                Expanded(
                  child: D2Button(
                    label: t.online.declineFriendshipRequest,
                    kind: D2ButtonKind.secondary,
                    expand: true,
                    onPressed: () => bloc.add(
                      UserEvent(
                        user,
                        UserUserAction.declineRequest,
                        confirmationMessage: t.online.requestDeclined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: D2Button(
                    label: t.online.acceptFriendshipRequest,
                    kind: D2ButtonKind.accent,
                    expand: true,
                    onPressed: () => bloc.add(
                      UserEvent(
                        user,
                        UserUserAction.acceptRequest,
                        confirmationMessage: t.online.requestAccepted,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            D2Button(
              label: t.online.cancelFriendshipRequest,
              kind: D2ButtonKind.secondary,
              expand: true,
              onPressed: () => bloc.add(
                UserEvent(
                  user,
                  UserUserAction.cancelRequest,
                  confirmationMessage: t.online.requestCancelled,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _FriendMenu { remove, block }

class _FriendRow extends StatelessWidget {
  final LpsUser user;
  final void Function(LpsUser friend)? onInvite;

  const _FriendRow({required this.user, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final now = DateTime.now();
    final online = user.isOnline(now);
    final bloc = context.read<UserActionsBloc>();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        OnlineProfileView.createRoute(
          context,
          userId: user.id,
          onInvite: onInvite,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
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
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: D2Text.body.copyWith(color: c.ink)),
                  Text(
                    formatLastSeen(t, user.lastSeenAt, now),
                    style: D2Text.caption.copyWith(
                      color: online ? c.ink : c.inkSoft,
                      fontWeight: online ? FontWeight.w500 : null,
                    ),
                  ),
                ],
              ),
            ),
            if (online) ...[
              const SizedBox(width: 6),
              D2Button(
                label: t.online.inviteShort,
                kind: D2ButtonKind.accent,
                semanticLabel: t.online.inviteNamed(name: user.name),
                onPressed: () => inviteFriend(context, user, onInvite),
              ),
            ],
            PopupMenuButton<_FriendMenu>(
              tooltip: user.name,
              icon: D2Icon(D2Glyph.more, size: 22, color: c.ink),
              onSelected: (item) => bloc.add(switch (item) {
                _FriendMenu.remove => UserEvent(
                  user,
                  UserUserAction.removeFromFriends,
                  confirmationMessage: t.online.removedFromFriends(
                    login: user.name,
                  ),
                  undoable: true,
                ),
                _FriendMenu.block => UserEvent(
                  user,
                  UserUserAction.banUser,
                  confirmationMessage: t.online.userBanned,
                ),
              }),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _FriendMenu.remove,
                  child: Text(t.online.removeFromFriends, style: D2Text.body),
                ),
                PopupMenuItem(
                  value: _FriendMenu.block,
                  child: Text(
                    t.online.ban,
                    style: D2Text.body.copyWith(color: c.error),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
