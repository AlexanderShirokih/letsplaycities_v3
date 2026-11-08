import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/utils/cache_list.dart';

void main() {
  List<int> contents(CacheList<int> cache, int maxValue) => [
    for (var i = 1; i <= maxValue; i++)
      if (cache.get((e) => e == i) != null) i,
  ];

  test('put on a full cache keeps the new item and drops the oldest', () {
    final cache = CacheList<int>(3);

    for (var i = 1; i <= 6; i++) {
      cache.put(i);
    }

    expect(contents(cache, 6), [4, 5, 6]);
  });

  test('getOrFetch caches the fetched item when the cache is full', () async {
    final cache = CacheList<int>(2)
      ..put(1)
      ..put(2);
    var fetches = 0;

    Future<int> fetchThree() async {
      fetches++;
      return 3;
    }

    await cache.getOrFetch((e) => e == 3, fetchThree);
    await cache.getOrFetch((e) => e == 3, fetchThree);

    expect(fetches, 1);
    expect(contents(cache, 3), [2, 3]);
  });
}
