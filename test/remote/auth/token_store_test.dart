import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/auth/token_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureTokenStore', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('token store round-trip and clear', () async {
      const store = SecureTokenStore();
      expect(await store.read(), isNull);

      await store.write('abc');
      expect(await store.read(), 'abc');

      await store.write('def');
      expect(await store.read(), 'def');

      await store.clear();
      expect(await store.read(), isNull);
    });
  });

  test('MemoryTokenStore round-trip and clear', () async {
    final store = MemoryTokenStore();
    expect(await store.read(), isNull);

    await store.write('abc');
    expect(await store.read(), 'abc');

    await store.clear();
    expect(await store.read(), isNull);
  });
}
