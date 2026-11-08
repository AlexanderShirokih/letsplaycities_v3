import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the access token of the signed-in user.
abstract class TokenStore {
  /// The token, or `null` if the user is not signed in.
  Future<String?> read();

  Future<void> write(String token);

  /// Forgets the token, which signs the user out.
  Future<void> clear();
}

/// [TokenStore] in the platform secure storage.
class SecureTokenStore implements TokenStore {
  static const _key = 'access_token';

  final FlutterSecureStorage _storage;

  const SecureTokenStore([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// [TokenStore] that lives as long as the object: for tests and for the LAN
/// game, which has no persistent account.
class MemoryTokenStore implements TokenStore {
  String? _token;

  MemoryTokenStore([this._token]);

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
