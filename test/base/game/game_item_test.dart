import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/game/game_item.dart';
import 'package:lets_play_cities/base/users.dart';

Player _player(String name) => Player(
  LocalAccountInfo(name: name, picture: const PlaceholderPictureSource()),
);

void main() {
  final owner = _player('owner');
  final other = _player('other');

  group('CityInfo', () {
    test('equal items have equal hash codes', () {
      final a = CityInfo(owner: owner, city: 'москва', countryCode: 7);
      final b = CityInfo(owner: owner, city: 'москва', countryCode: 7);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality compares city, status and country code', () {
      final base = CityInfo(owner: owner, city: 'москва', countryCode: 7);

      expect(
        base,
        isNot(CityInfo(owner: owner, city: 'анапа', countryCode: 7)),
      );
      expect(
        base,
        isNot(CityInfo(owner: owner, city: 'москва', countryCode: 8)),
      );
      for (final status in CityStatus.values) {
        for (final otherStatus in CityStatus.values) {
          expect(
            CityInfo(owner: owner, city: 'москва', status: status) ==
                CityInfo(owner: owner, city: 'москва', status: otherStatus),
            status == otherStatus,
          );
        }
      }
    });

    test('equality ignores the owner', () {
      expect(
        CityInfo(owner: owner, city: 'москва'),
        CityInfo(owner: other, city: 'москва'),
      );
    });

    test('a set keeps one of the equal items', () {
      final items = {
        CityInfo(owner: owner, city: 'москва'),
        CityInfo(owner: owner, city: 'москва'),
        CityInfo(owner: owner, city: 'москва', countryCode: 7),
      };

      expect(items.length, 2);
    });

    test('has the same base data as a city of the same owner', () {
      final city = CityInfo(owner: owner, city: 'москва', countryCode: 7);

      expect(
        city.hasTheSameBaseData(CityInfo(owner: owner, city: 'москва')),
        isTrue,
      );
      expect(
        city.hasTheSameBaseData(CityInfo(owner: other, city: 'москва')),
        isFalse,
      );
      expect(
        city.hasTheSameBaseData(CityInfo(owner: owner, city: 'анапа')),
        isFalse,
      );
    });
  });

  group('MessageInfo', () {
    test('equal items have equal hash codes', () {
      final a = MessageInfo(message: 'привет', owner: owner);
      final b = MessageInfo(message: 'привет', owner: other);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality compares the message', () {
      expect(
        MessageInfo(message: 'привет', owner: owner),
        isNot(MessageInfo(message: 'пока', owner: owner)),
      );
    });

    test('never equals a city with the same text', () {
      expect(
        MessageInfo(message: 'москва', owner: owner),
        isNot(CityInfo(owner: owner, city: 'москва')),
      );
    });
  });
}
