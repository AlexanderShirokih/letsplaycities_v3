// @dart=2.9

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('test loading embedded dictionary completes normally', () async {
    expect(() async => await DictionaryFactory().createDictionary(),
        returnsNormally);
  }, timeout: Timeout(Duration(seconds: 1)));
}
