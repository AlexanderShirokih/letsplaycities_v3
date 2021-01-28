import 'dart:collection';

/// Collection that saves last `n` elements in queue.
class CacheList<T> {
  final int capacity;
  final Queue<T> _cachedProfilesInfo;

  CacheList(this.capacity)
      : assert(capacity > 0),
        _cachedProfilesInfo = ListQueue(capacity);

  /// Puts [data] to cache list. Displaces last item if cache queue if full.
  void put(T data) {
    if (_cachedProfilesInfo.length < capacity) {
      _cachedProfilesInfo.add(data);
    } else {
      _cachedProfilesInfo.removeFirst();
    }
  }

  /// Removes [target] from list
  void remove(T target) => _cachedProfilesInfo.remove(target);

  /// Removes all elements satisfying given predicate
  void removeWhere(bool Function(T element) predicate) =>
      _cachedProfilesInfo.removeWhere(predicate);

  /// Returns first element satisfying given predicate or `null` if element was
  /// not found.
  T? get(bool Function(T) selector) {
    for (final item in _cachedProfilesInfo) {
      if (selector(item)) {
        return item;
      }
    }
    return null;
  }

  /// Returns first element satisfying given predicate or fetches new element
  /// from [consumer] and adds it to the queue if element was not found.
  Future<T> getOrFetch(
    bool Function(T) predicate,
    Future<T> Function() consumer,
  ) async {
    final existing = get(predicate);

    if (existing != null) {
      return existing;
    } else {
      final fetched = await consumer();
      put(fetched);
      return fetched;
    }
  }

  /// Clears cache queue
  void clear() => _cachedProfilesInfo.clear();
}
