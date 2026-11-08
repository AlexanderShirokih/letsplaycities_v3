import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/repositories/game_session_repo.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

import 'message_bubble.dart';

/// Represents ListView containing cities and messages
class CitiesList extends StatelessWidget {
  const CitiesList({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<GameSessionRepository>().gameItemsRepository;
    return Expanded(
      child: StreamBuilder<List<GameItem>>(
        stream: items.getItemsList(),
        initialData: items.items,
        builder: (context, state) => ListView(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: state.hasData
              ? state.requireData.reversed
                    .map((e) => GameItemListTile(e))
                    .toList(growable: false)
              : [],
        ),
      ),
    );
  }
}

/// A bubble of the city or the chat message: the moves of the left player
/// are on the left, of the right player on the right.
class GameItemListTile extends StatelessWidget {
  final GameItem _gameItem;

  const GameItemListTile(this._gameItem, {super.key});

  @override
  Widget build(BuildContext context) {
    final item = _gameItem;
    final isLeft = item.owner.position == Position.left;

    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Align(
        alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 290),
          child: item is CityInfo
              ? _buildCity(context, item)
              : MessageBubble(item as MessageInfo, tailLeft: isLeft),
        ),
      ),
    );
  }

  Widget _buildCity(BuildContext context, CityInfo city) {
    final c = D2Colors.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 7, 12, 9),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: c.edge, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(context, city),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              cityNameSpans(city.city.toTitleCase(), c),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context, CityInfo cityInfo) {
    final c = D2Colors.of(context);

    return switch (cityInfo.status) {
      CityStatus.ok => CityFlag(cityInfo.countryCode),
      CityStatus.waiting => D2Icon(D2Glyph.timer, size: 20, color: c.inkSoft),
      CityStatus.error => D2Icon(D2Glyph.warning, size: 20, color: c.error),
    };
  }
}

/// [city] with its last suitable letter highlighted and the letters after it
/// dimmed
TextSpan cityNameSpans(String city, D2Colors c, {double fontSize = 17}) {
  final text = D2Text.body.copyWith(fontSize: fontSize, color: c.ink);
  final letter = D2Text.body.copyWith(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    fontVariations: const [FontVariation('wght', 700)],
    color: c.letter,
  );
  final tail = text.copyWith(color: c.inkSoft);
  final last = indexOfLastSuitableChar(city);

  return TextSpan(
    children: [
      if (last > 0) TextSpan(text: city.substring(0, last), style: text),
      TextSpan(text: city[last], style: letter),
      if (last + 1 < city.length)
        TextSpan(text: city.substring(last + 1), style: tail),
    ],
  );
}

/// Flag of the country with [countryCode], 24x16 with rounded corners
class CityFlag extends StatelessWidget {
  final int countryCode;

  const CityFlag(this.countryCode, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Container(
      width: 24,
      height: 16,
      clipBehavior: Clip.antiAlias,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: c.shadow.withAlpha(64)),
      ),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(3)),
      child: Image.asset(
        'assets/images/flags/flag_$countryCode.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
