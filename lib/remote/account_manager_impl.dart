import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

class AccountManagerImpl extends AccountManager {
  final GamePreferences _preferences;

  /// Talks to the main server, which keeps the accounts.
  final ApiRepositoryFactory _apiRepositories;

  AccountManagerImpl(this._preferences, this._apiRepositories);

  // replaced in protocol v1 task 2: the account comes from `GET /v1/me`; there
  // is no user id to ask the old profile endpoint with until then.
  @override
  Future<RemoteAccount?> getLastSignedInAccount() async => null;

  @override
  Future<RemoteAccount> signUp(RemoteSignUpData signUpData) async {
    final response = await _apiRepositories.clientFor().signUp(signUpData);

    await _apiRepositories.tokens.write(response.accessToken);
    _apiRepositories.cache.clear();

    return RemoteAccount(
      userId: response.userId,
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
  Future signOut() => _apiRepositories.tokens.clear().then((_) {
    _apiRepositories.cache.clear();
  });
}
