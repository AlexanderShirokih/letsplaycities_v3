import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lets_play_cities/base/data/city_data.dart';
import 'package:lets_play_cities/base/game/GameItem.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

/// Represents ListView containing cities and messages
class CitiesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Expanded(
    child: ListView.builder(
      reverse: true,
      itemCount: 10,
      itemBuilder: (context, index) {
        return _CityItemListTile(CityInfo(
            city: index % 2 == 0 ? "Left" : "Right", //"Керчь",
            position: index % 2 == 0 ? Position.LEFT : Position.RIGHT));
      },
    ),
  );
}

class _CityItemListTile extends StatelessWidget {
  final GameItem _gameItem;

  _CityItemListTile(this._gameItem);

  @override
  Widget build(BuildContext context) => ListTile(
    title: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: _gameItem.position == Position.LEFT
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
          margin: EdgeInsets.zero,
          decoration: _buildDecoration(),
          child: _buildText(context),
        ),
      ],
    ),
  );

  BoxDecoration _buildDecoration() {
    const kFillColor = const Color(0xFFFFD2AE);
    const kBorderColor = const Color(0xFFE9B77B);
    const kMessageMe = const Color(0xFFAEF1B0);
    const kMessageOther = const Color(0xFFAFB7F4);

    return BoxDecoration(
      color: (_gameItem is CityInfo)
          ? kFillColor
          : (_gameItem.position == Position.LEFT ? kMessageOther : kMessageMe),
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(
        width: 1.0,
        color: kBorderColor,
        style: _gameItem is CityInfo ? BorderStyle.solid : BorderStyle.none,
      ),
    );
  }

  Widget _buildText(BuildContext context) {
    const kForegroundSpanColor = const Color(0xFF0000FF);

    if (_gameItem is CityInfo) {
      final textStyle =
      Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 16);
      final spanTextStyle = textStyle.copyWith(color: kForegroundSpanColor);
      return RichText(text: _buildCitySpans(textStyle, spanTextStyle));
    }
    return Text((_gameItem as MessageInfo).message);
  }

  TextSpan _buildCitySpans(TextStyle textStyle, TextStyle spanTextStyle) {
    final city = (_gameItem as CityInfo).city;
    final lastSuitable = indexOfLastSuitableChar(city);

    return TextSpan(children: [
      // Highlight first letter
      TextSpan(text: city[0], style: spanTextStyle),
      // Show main test
      TextSpan(
          text: (_gameItem as CityInfo).city.substring(1, lastSuitable),
          style: textStyle),
      // Highlight last suitable char
      TextSpan(text: city[lastSuitable], style: spanTextStyle),
      // Show trailing letters is exists
      if (city.length != lastSuitable + 1)
        TextSpan(text: city.substring(lastSuitable + 1), style: textStyle),
    ]);
  }
}