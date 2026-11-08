import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';

import 'dictionary_test_files.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDir;
  late int embeddedVersion;

  File downloaded() => File('${supportDir.path}/data-last.db2');
  File downloadedMeta() => File('${supportDir.path}/data-last.db2.meta');

  setUp(() async {
    supportDir = await Directory.systemTemp.createTemp('dictionary_factory');
    fakeApplicationSupportDirectory(supportDir);
    embeddedVersion = await embeddedDictionaryVersion();
    DictionaryFactory.invalidateCache();
  });

  tearDown(() async {
    DictionaryFactory.invalidateCache();
    fakeApplicationSupportDirectory(null);
    await supportDir.delete(recursive: true);
  });

  test('loads the embedded dictionary when nothing was downloaded', () async {
    final dictionary = await DictionaryFactory().createDictionary();

    expect(await DictionaryFactory.latestVersion(), embeddedVersion);
    expect(dictionary.getAll(), hasLength(greaterThan(1000)));
    expect(dictionary.getAll(), contains('москва'));
  });

  test('prefers a downloaded dictionary with a newer version', () async {
    final version = embeddedVersion + 1;
    await downloaded().writeAsBytes(
      buildDictionaryFile(version, {'тестоград': 91}),
    );
    await downloadedMeta().writeAsString('{"version": $version}');

    final dictionary = await DictionaryFactory().createDictionary();

    expect(await DictionaryFactory.latestVersion(), version);
    expect(dictionary.getAll().keys, ['тестоград']);
    expect(dictionary.getCountryCode('тестоград'), 91);
  });

  group(
    'falls back to the embedded dictionary when the downloaded meta is',
    () {
      const brokenMetas = {
        'empty': '',
        'truncated': '{"vers',
        'missing the version': '{}',
        'not an object': '[1]',
        'holding a non-integer version': '{"version": "81"}',
      };

      brokenMetas.forEach((description, meta) {
        test(description, () async {
          await downloaded().writeAsBytes(
            buildDictionaryFile(embeddedVersion + 1, {'тестоград': 91}),
          );
          await downloadedMeta().writeAsString(meta);

          expect(await DictionaryFactory.latestVersion(), embeddedVersion);
          final dictionary = await DictionaryFactory().createDictionary();
          expect(dictionary.getAll(), contains('москва'));
        });
      });
    },
  );
}
