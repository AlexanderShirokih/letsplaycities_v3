import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/game/management.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/base/users.dart';

Player _player(String name) => Player(
  LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late StreamController<GameEvent> events;
  late GameItemsRepository repository;
  late Player player;

  setUp(() {
    events = StreamController<GameEvent>.broadcast();
    repository = GameItemsRepository(events.stream);
    player = _player('player');
  });

  tearDown(() => events.close());

  test('returns the same items stream on every call', () {
    expect(
      identical(repository.getItemsList(), repository.getItemsList()),
      isTrue,
    );
  });

  test('keeps the history when the list is listened to again', () async {
    final first = repository.getItemsList().listen(null);
    events
      ..add(Accepted('москва', player, status: CityStatus.ok))
      ..add(Accepted('анапа', player, status: CityStatus.ok));
    await _flush();
    await first.cancel();

    final sizes = <int>[];
    repository.getItemsList().listen((items) => sizes.add(items.length));
    events.add(Accepted('архангельск', player, status: CityStatus.ok));
    await _flush();

    expect(sizes, [3]);
    expect(repository.items.length, 3);
  });

  test('applies each event once with several listeners', () async {
    repository.getItemsList().listen(null);
    repository.getItemsList().listen(null);

    events.add(MessageEvent('привет', player));
    await _flush();

    expect(repository.items.length, 1);
  });

  test('appends a repeated message instead of replacing it', () async {
    final sizes = <int>[];
    repository.getItemsList().listen((items) => sizes.add(items.length));

    events
      ..add(MessageEvent('ок', player))
      ..add(MessageEvent('ок', player));
    await _flush();

    expect(sizes, [1, 2]);
  });

  test('updates the status of a city in place', () async {
    final sizes = <int>[];
    repository.getItemsList().listen((items) => sizes.add(items.length));

    events
      ..add(Accepted('москва', player, status: CityStatus.waiting))
      ..add(MessageEvent('ок', player))
      ..add(Accepted('москва', player, status: CityStatus.ok));
    await _flush();

    expect(sizes, [1, 2, 2]);
    final city = repository.items.first as CityInfo;
    expect(city.city, 'москва');
    expect(city.status, CityStatus.ok);
  });
}
