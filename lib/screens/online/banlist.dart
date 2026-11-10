import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/remote/bloc/user_actions_bloc.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/online/profile.dart';

import 'base_list_fetching_screen_mixin.dart';
import 'common_online_widgets.dart';

/// Blocked users list screen
/// Provides a list of users which was blocked by player and the way to remove users from this list
class OnlineBanlistScreen extends StatelessWidget
    with BaseListFetchingScreenMixin<LpsUser> {
  @override
  UserFetchType get fetchEvent => UserFetchType.getBanlist;

  const OnlineBanlistScreen({super.key});

  @override
  Widget getOnListEmptyPlaceHolder(BuildContext context) => D2EmptyState(
    art: const D2TileArt(glyph: D2Glyph.ban),
    title: context.t.online.blacklistEmptyTitle,
  );

  @override
  Widget buildItem(BuildContext context, LpsUser data) =>
      _BannedRow(user: data);

  @override
  Widget buildBody(
    BuildContext context,
    List<LpsUser> data,
    bool hasMore,
    Object? moreError,
  ) =>
      _BannedList(users: data, placeholder: getOnListEmptyPlaceHolder(context));
}

/// The banned users in one card. A user being unbanned leaves the list at
/// once, without waiting for the undo snackbar, and comes back on undo or on
/// an error.
class _BannedList extends StatefulWidget {
  final List<LpsUser> users;
  final Widget placeholder;

  const _BannedList({required this.users, required this.placeholder});

  @override
  State<_BannedList> createState() => _BannedListState();
}

class _BannedListState extends State<_BannedList> {
  final _hidden = <int>{};

  void _onActionState(BuildContext context, UserActionsState state) {
    if (state is UserActionConfirmationState) {
      setState(() => _hidden.add(state.sourceEvent.target.id));
    } else if (state is UserActionsInitial || state is UserActionErrorState) {
      setState(_hidden.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final users = [
      for (final user in widget.users)
        if (!_hidden.contains(user.id)) user,
    ];

    return BlocListener<UserActionsBloc, UserActionsState>(
      listener: _onActionState,
      child: users.isEmpty
          ? widget.placeholder
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              children: [
                D2Card(
                  padding: EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        for (var i = 0; i < users.length; i++) ...[
                          if (i > 0) Container(height: 2, color: c.bg),
                          _BannedRow(user: users[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BannedRow extends StatelessWidget {
  final LpsUser user;

  const _BannedRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);

    return InkWell(
      onTap: () => Navigator.push(
        context,
        OnlineProfileView.createRoute(context, userId: user.id),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              lpsUserAvatar(context, user),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D2Text.body.copyWith(fontSize: 15, color: c.ink),
                ),
              ),
              const SizedBox(width: 8),
              D2Button(
                label: t.online.unban,
                kind: D2ButtonKind.tonal,
                semanticLabel: t.online.unbanNamed(name: user.name),
                onPressed: () => context.read<UserActionsBloc>().add(
                  UserEvent(
                    user,
                    UserUserAction.unbanUser,
                    confirmationMessage: t.online.banlistEntryRemoved,
                    undoable: true,
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
