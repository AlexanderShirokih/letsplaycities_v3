import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/users.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

/// Chat message: violet with white text for the player's own messages.
///
/// The others' messages are [AppColors.surface] with the card shadow in the
/// moves feed, or [AppColors.bg] when the bubble already lies [onSurface].
/// The corner on the [tailLeft] side is sharper.
class MessageBubble extends StatelessWidget {
  final MessageInfo message;
  final bool tailLeft;
  final bool onSurface;

  const MessageBubble(
    this.message, {
    super.key,
    required this.tailLeft,
    this.onSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isMine = message.owner is Player;

    final fill = isMine ? c.violet : (onSurface ? c.bg : c.surface);
    final shadow = onSurface
        ? null
        : (isMine ? c.shadow.withAlpha(56) : c.edge);

    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(tailLeft ? 6 : 16),
          bottomRight: Radius.circular(tailLeft ? 16 : 6),
        ),
        boxShadow: shadow == null
            ? null
            : [BoxShadow(color: shadow, offset: const Offset(0, 3))],
      ),
      child: Text(
        message.message,
        style: AppText.bodyRegular.copyWith(
          fontSize: 16,
          height: 1.3,
          color: isMine ? AppColors.light.surface : c.ink,
        ),
      ),
    );
  }
}
