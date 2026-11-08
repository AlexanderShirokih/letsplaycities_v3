import 'package:async/async.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

class AccountManagerImpl extends AccountManager {
  final GamePreferences _preferences;

  /// Talks to the main server, which keeps the accounts.
  final ApiRepositoryFactory _apiRepositories;

  final AsyncCache<RemoteAccount> _fetchedAccount = AsyncCache(
    const Duration(minutes: 5),
  );

  AccountManagerImpl(this._preferences, this._apiRepositories);

  @override
  Future<RemoteAccount?> getLastSignedInAccount() async {
    var credentials = _preferences.currentCredentials;

    if (credentials == null) return null;

    return _fetchOrInvalidate(() async {
      final profile = await _apiRepositories
          .forCredential(credentials)
          .getProfileInfo(
            BaseProfileInfo(userId: credentials.userId, login: ''),
            true,
          );

      return RemoteAccount(
        credential: credentials,
        authType: profile.authType,
        role: profile.role,
        name: profile.login,
        canReceiveMessages: _preferences.onlineChatEnabled,
        pictureUri: profile.pictureUrl,
      );
    });
  }

  /// [AsyncCache] keeps a failed future until it expires, so drop it here and
  /// let the next call (e.g. the Reload button) fetch again.
  Future<RemoteAccount> _fetchOrInvalidate(
    Future<RemoteAccount> Function() fetch,
  ) async {
    try {
      return await _fetchedAccount.fetch(fetch);
    } catch (_) {
      _fetchedAccount.invalidate();
      rethrow;
    }
  }

  @override
  Future<RemoteAccount> signUp(RemoteSignUpData signUpData) async {
    // Not through _fetchedAccount.fetch: it would return whatever account or
    // error is cached instead of signing up. Dropping the cache makes the
    // next getLastSignedInAccount load the new account from the server.
    final account = await _signUp(signUpData);
    _fetchedAccount.invalidate();
    return account;
  }

  Future<RemoteAccount> _signUp(RemoteSignUpData signUpData) async {
    final response = await _apiRepositories
        .clientFor(Credential.empty())
        .signUp(signUpData);

    final credential = Credential(
      userId: response.userId,
      accessToken: response.accessToken,
    );

    await _preferences.setCurrentCredentials(credential);
    _apiRepositories.cache.clear();

    return RemoteAccount(
      credential: credential,
      name: response.login,
      pictureUri: getPictureUrlOrNull(
        _apiRepositories.serverConfig,
        response.userId,
        response.pictureHash,
      ),
      canReceiveMessages: _preferences.onlineChatEnabled,
      role: response.role,
      authType: response.authType,
    );
  }

  // TODO: Clear cookies here, when we implement cookies management
  @override
  Future signOut() => _preferences.setCurrentCredentials(null).then((_) {
    _fetchedAccount.invalidate();
    _apiRepositories.cache.clear();
  });
}
