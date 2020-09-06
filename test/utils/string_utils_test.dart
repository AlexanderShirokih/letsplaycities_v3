import 'package:test/test.dart';
import 'package:lets_play_cities/utils/string_utils.dart';

main() {
  test('String.toTitleCase() converts string properly', () {
    var source = [
      "Hello dart test",
      "Hello Dart Test",
      "hello-dart test",
      "hellodarttest",
      "париж",
      "нью-йорк"
    ];
    var expected = [
      "Hello Dart Test",
      "Hello Dart Test",
      "Hello-Dart Test",
      "Hellodarttest",
      "Париж",
      "Нью-Йорк"
    ];
    expect(source.map((e) => e.toTitleCase()), equals(expected));
  });

  test('indexOfLastSuitableChar() returns correct indices', () {
    expect(indexOfLastSuitableChar("ыь"), 0);
    expect(indexOfLastSuitableChar("Тест"), equals("Тест".lastIndexOf("т")));
    expect(indexOfLastSuitableChar("Тесть"), equals("Тесть".lastIndexOf("т")));
    expect(indexOfLastSuitableChar("холмы"), equals("холмы".lastIndexOf("м")));
  });

  test('String.format() formats string correctly', () {
    expect("no args".format(["unused"]), equals("no args"));
    expect(r"%1$ %2$".format(["Hello", "world"]), equals("Hello world"));
  });
}
