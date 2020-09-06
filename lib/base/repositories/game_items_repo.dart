import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/game/management.dart';

/// Repository that holds game item data such as words and messages
class GameItemsRepository {
  final Stream<GameEvent> _eventsStream;
  final List<GameItem> _itemsList = [];

  GameItemsRepository(this._eventsStream);

  /// Emits [GameItem] events such as [CityInfo] and [MessageInfo]
  /// from the session event channel.
  Stream<GameItem> _getGameItems() => _eventsStream
          .where((event) => event is Accepted || event is MessageEvent)
          .map((event) {
        if (event is Accepted) {
          return CityInfo(
            city: event.word,
            owner: event.owner,
            status: event.status ?? CityStatus.ERROR,
            countryCode: event.countryCode ?? 0,
          );
        } else if (event is MessageEvent) {
          return MessageInfo(message: event.message, owner: event.owner);
        } else
          throw ("Error filtering Word|Message events !");
      });

  int _findWithTheSameBase(GameItem item) =>
      _itemsList.lastIndexWhere((element) => element.hasTheSameBaseData(item));

  /// Returns stream containing list of actual [GameItem] items.
  Stream<List<GameItem>> getItemsList() => _getGameItems().asyncMap((event) {
        final curr = _findWithTheSameBase(event);
        if (curr != -1)
          _itemsList[curr] = event;
        else
          _itemsList.add(event);

        return _itemsList;
      });
}
