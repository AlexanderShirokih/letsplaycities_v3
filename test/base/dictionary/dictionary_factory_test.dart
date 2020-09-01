import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('test loading embedded dictionary completes normally', () async {
    expect(() async => await DictionaryFactory().loadDictionary(),
        returnsNormally);
  }, timeout: Timeout(Duration(seconds: 1)));
}
