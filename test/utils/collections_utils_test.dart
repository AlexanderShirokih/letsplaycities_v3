import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/utils/collections_utils.dart';

void main() {
  group('distinctBy', () {
    final pairs = [('a', 1), ('b', 5), ('a', 1)];

    Iterable<(String, int)> merged() => pairs.distinctBy(
      (pair) => pair.$1,
      onDuplicate: (old, current) => (old.$1, old.$2 + current.$2),
    );

    test('merges duplicates in first-occurrence order', () {
      expect(merged().toList(), [('a', 2), ('b', 5)]);
    });

    test('gives the same result when iterated again', () {
      final distinct = merged();

      expect(distinct.toList(), [('a', 2), ('b', 5)]);
      expect(distinct.toList(), [('a', 2), ('b', 5)]);
      expect(distinct.length, 2);
    });

    test('keeps the first element when there is no merge callback', () {
      final distinct = [('a', 1), ('a', 2)].distinctBy((pair) => pair.$1);

      expect(distinct.toList(), [('a', 1)]);
      expect(distinct.toList(), [('a', 1)]);
    });
  });
}
