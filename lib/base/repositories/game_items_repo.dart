import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/management.dart';
import 'package:lets_play_cities/base/game_session.dart';

/// Repository that holds game item data
class GameItemsRepository {
  final GameSession _session;
  final List<GameItem> _itemsList = [];

  GameItemsRepository(this._session);

  /// Emits [GameItem] events such as [CityInfo] and [MessageInfo]
  /// from the session event channel.
  Stream<GameItem> _getGameItems() => _session.eventChannel
          .getInputEvents()
          .where((event) => event is InputGameEvent)
          .map((event) {
        if (event is InputWordEvent) {
          return CityInfo(
              city: event.word, owner: _session.getUserById(event.ownerId));
        } else if (event is InputMessageEvent) {
          return MessageInfo(
              message: event.message,
              owner: _session.getUserById(event.ownerId));
        } else
          throw ("Unexpected InputGameEvent implementation");
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
