import 'package:flutter_test/flutter_test.dart' show throwsAssertionError;
import 'package:lets_play_cities/base/dictionary/city_properties.dart';
import 'package:test/test.dart';

void main() {
  group('CityProperties', () {
    test('.used false by default', () {
      expect(
          CityProperties(difficulty: 1, countryCode: 10).used, equals(false));
      expect(CityProperties.fromBitmask(0xFF).used, equals(false));
    });

    test('.markUsed() raises flag once', () {
      final props = CityProperties(difficulty: 1, countryCode: 10);

      props.markUsed();
      expect(props.used, equals(true));
      props.markUsed();
      expect(props.used, equals(true));
    });

    test('.reset() resets the flag', () {
      final props = CityProperties(difficulty: 1, countryCode: 10);

      props.markUsed();
      props.reset();
      expect(props.used, equals(false));
    });

    test('.difficulty bits sets correctly', () {
      expect(
          CityProperties(difficulty: 2, countryCode: 10).difficulty, equals(2));
      expect(CityProperties.fromBitmask(0x020000).difficulty, equals(2));
    });

    test('.countryCode bits sets correctly', () {
      expect(CityProperties(difficulty: 0, countryCode: 123).countryCode,
          equals(123));
      expect(CityProperties.fromBitmask(123).countryCode, equals(123));
    });

    group('input data asserts', () {
      test('difficulty works in range 0-2', () {
        [0, 1, 2].forEach((d) {
          expect(() => CityProperties(difficulty: d, countryCode: 1),
              returnsNormally);
        });
      });

      test('difficulty throws out of range', () {
        [-1, 3].forEach((d) {
          expect(() => CityProperties(difficulty: d, countryCode: 1),
              throwsAssertionError);
        });
      });

      test('countryCode works in range 0-255', () {
        [0, 1, 2, 254, 255].forEach((cc) {
          expect(() => CityProperties(difficulty: 0, countryCode: cc),
              returnsNormally);
        });
      });
    });
  });
}
