import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/repositories/game_session_repo.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as themes;
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

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

class GameItemListTile extends StatelessWidget {
  final GameItem _gameItem;

  const GameItemListTile(this._gameItem, {super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    title: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _gameItem.owner.position == Position.left
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: 240.0),
          padding: EdgeInsets.fromLTRB(10.0, 10.0, 16.0, 10.0),
          margin: EdgeInsets.zero,
          decoration: _buildDecoration(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_gameItem is CityInfo) _buildIcon(_gameItem),
              const SizedBox(width: 8.0),
              Flexible(child: _buildText(context)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildIcon(CityInfo cityInfo) {
    switch (cityInfo.status) {
      case CityStatus.ok:
        return createFlagImage(cityInfo.countryCode);
      case CityStatus.waiting:
        return Icon(Icons.pending_outlined);
      case CityStatus.error:
        return Icon(Icons.error_outline, color: Colors.red);
    }
  }

  BoxDecoration _buildDecoration(BuildContext context) {
    final theme = context.watch<themes.Theme>();

    return BoxDecoration(
      color: (_gameItem is CityInfo)
          ? theme.fillColor
          : (_gameItem.owner.position == Position.left
                ? theme.messageOther
                : theme.messageMe),
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(
        width: 1.0,
        color: theme.borderColor,
        style: _gameItem is CityInfo ? BorderStyle.solid : BorderStyle.none,
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    final theme = context.watch<themes.Theme>();
    if (_gameItem is CityInfo) {
      final textStyle = Theme.of(context).textTheme.bodyLarge!
          .copyWith(fontSize: 18, fontWeight: FontWeight.w600);
      final spanTextStyle = textStyle.copyWith(color: theme.wordSpanColor);
      return RichText(
        text: _buildCitySpans(textStyle, spanTextStyle),
        overflow: TextOverflow.clip,
      );
    }
    return Text((_gameItem as MessageInfo).message);
  }

  TextSpan _buildCitySpans(TextStyle textStyle, TextStyle spanTextStyle) {
    final city = (_gameItem as CityInfo).city.toTitleCase();
    final lastSuitable = indexOfLastSuitableChar(city);

    return TextSpan(
      children: [
        // Highlight first letter
        TextSpan(text: city[0], style: spanTextStyle),
        // Show main test
        TextSpan(text: city.substring(1, lastSuitable), style: textStyle),
        // Highlight last suitable char
        TextSpan(text: city[lastSuitable], style: spanTextStyle),
        // Show trailing letters is exists
        if (city.length != lastSuitable + 1)
          TextSpan(text: city.substring(lastSuitable + 1), style: textStyle),
      ],
    );
  }
}
