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
  Stream<GameItem> getGameItems() => _eventsStream
      .where((event) => event is Accepted || event is MessageEvent)
      .map((event) {
        if (event is Accepted) {
          return CityInfo(
            city: event.word,
            owner: event.owner,
            status: event.status ?? CityStatus.error,
            countryCode: event.countryCode ?? 0,
          );
        } else if (event is MessageEvent) {
          return MessageInfo(message: event.message, owner: event.owner);
        } else {
          throw ('Error filtering Word|Message events !');
        }
      });

  int _findWithTheSameBase(GameItem item) =>
      _itemsList.lastIndexWhere((element) => element.hasTheSameBaseData(item));

  // Built once: a second pipeline would apply every event to [_itemsList]
  // again.
  late final Stream<List<GameItem>> _itemsListStream = getGameItems().asyncMap((
    event,
  ) {
    // A city comes again when its status changes; a message is always new.
    final curr = event is CityInfo ? _findWithTheSameBase(event) : -1;
    if (curr != -1) {
      _itemsList[curr] = event;
    } else {
      _itemsList.add(event);
    }

    return _itemsList;
  });

  /// Items received so far.
  List<GameItem> get items => List.unmodifiable(_itemsList);

  /// Returns stream containing list of actual [GameItem] items.
  /// Every call returns the same stream.
  Stream<List<GameItem>> getItemsList() => _itemsListStream;
}
