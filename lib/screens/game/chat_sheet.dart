import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

import 'message_bubble.dart';
import 'user_avatar.dart';

/// «Чат» button with the number of the opponent's messages received since
/// the chat was open the last time. Opens [ChatSheet].
///
/// Requires [GameSessionRepository].
class ChatButton extends StatefulWidget {
  const ChatButton({super.key});

  @override
  State<ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<ChatButton> {
  late final GameSessionRepository _repository;
  late final StreamSubscription<GameItem> _items;

  var _open = false;
  var _unread = 0;

  @override
  void initState() {
    super.initState();
    _repository = context.read<GameSessionRepository>();
    _items = _repository.gameItemsRepository.getGameItems().listen((item) {
      if (!_open && item is MessageInfo && item.owner is! Player) {
        setState(() => _unread++);
      }
    });
  }

  @override
  void dispose() {
    _items.cancel();
    super.dispose();
  }

  Future<void> _openChat() async {
    setState(() {
      _open = true;
      _unread = 0;
    });

    await showAppSheet<void>(context, builder: (_) => ChatSheet(_repository));

    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return AppButton(
      label: t.game.chat,
      icon: AppGlyph.chat,
      kind: AppButtonKind.secondary,
      badge: _unread,
      semanticLabel: _unread > 0 ? t.game.chatUnread(count: _unread) : null,
      onPressed: _openChat,
    );
  }
}

/// Bottom sheet with the chat messages of the game and the message field
class ChatSheet extends StatefulWidget {
  final GameSessionRepository repository;

  const ChatSheet(this.repository, {super.key});

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final message = _input.text.trim();
    if (message.isEmpty) return;

    widget.repository.sendChatMessage(message);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);
    final items = widget.repository.gameItemsRepository;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: 398,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.game.chat,
                      style: AppText.title.copyWith(color: c.ink),
                    ),
                  ),
                  AppIconButton(
                    AppGlyph.close,
                    tooltip: t.design.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<GameItem>>(
                stream: items.getItemsList(),
                initialData: items.items,
                builder: (context, snapshot) {
                  final messages = (snapshot.data ?? const [])
                      .whereType<MessageInfo>()
                      .toList(growable: false);

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final i = messages.length - 1 - index;
                      final next = i + 1 < messages.length
                          ? messages[i + 1]
                          : null;

                      return _ChatRow(
                        messages[i],
                        lastOfOwner: !identical(next?.owner, messages[i].owner),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.edge)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: c.bg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          controller: _input,
                          autofocus: true,
                          onSubmitted: (_) => _send(),
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: c.violet,
                          style: AppText.bodyRegular.copyWith(
                            fontSize: 16,
                            color: c.ink,
                          ),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: t.game.messageHint,
                            hintStyle: AppText.bodyRegular.copyWith(
                              fontSize: 16,
                              color: c.inkSoft,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppSquareButton(
                      AppGlyph.send,
                      tooltip: t.game.send,
                      width: 52,
                      height: 52,
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The opponent's messages are on the left with the avatar under the last
/// one of a row, the player's own are violet on the right.
class _ChatRow extends StatelessWidget {
  static const _avatarSize = 32.0;

  final MessageInfo message;
  final bool lastOfOwner;

  const _ChatRow(this.message, {required this.lastOfOwner});

  @override
  Widget build(BuildContext context) {
    final isMine = message.owner is Player;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            lastOfOwner
                ? buildAppAvatarForUser(message.owner, size: _avatarSize)
                : const SizedBox(width: _avatarSize),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: MessageBubble(message, tailLeft: !isMine, onSurface: true),
          ),
        ],
      ),
    );
  }
}
