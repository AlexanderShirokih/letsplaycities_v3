extension IteratorExt<T> on Iterable<T> {
  /// Returns [Iterable] that passes only unique elements.
  /// Elements is comparing by [keySelector].
  /// When some element repeats, than [onDuplicate] calls to either ignore it
  /// (if [onDuplicate] is not provided or if it returns `null`)
  /// or replace with a new value.
  /// If element returning by [onDuplicate] is equals to original element or has
  /// a key that already exists it will be ignored.
  Iterable<T> distinctBy(Object Function(T) keySelector,
          {T Function(T old, T current) onDuplicate}) =>
      _DistinctIterable(this, keySelector, onDuplicate);
}

class _DistinctIterable<T> extends Iterable<T> {
  final Iterable<T> _iterable;
  final Object Function(T) _keySelector;
  final T Function(T old, T current) _onDuplicate;
  final Map<Object, T> uniqueElements = {};

  _DistinctIterable(
    this._iterable,
    this._keySelector,
    T Function(T, T) onDuplicate,
  ) : _onDuplicate = onDuplicate ?? ((old, curr) => null);

  @override
  Iterator<T> get iterator {
    _iterable.forEach((element) {
      final key = _keySelector(element);

      final old = uniqueElements[key];
      if (old != null) {
        final value = _onDuplicate(old, element);
        if (value != null) uniqueElements[_keySelector(value)] = value;
      } else {
        uniqueElements[key] = element;
      }
    });

    return uniqueElements.values.iterator;
  }
}
