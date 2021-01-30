import 'package:async/async.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

import 'account.dart';
import 'account_manager.dart';
import 'client/api_client.dart';

class AccountManagerImpl extends AccountManager {
  final GamePreferences _preferences;

  final AsyncCache<RemoteAccount> _fetchedAccount =
      AsyncCache(const Duration(minutes: 5));

  AccountManagerImpl(this._preferences);

  @override
  Future<RemoteAccount?> getLastSignedInAccount() async {
    var credentials = _preferences.currentCredentials;

    if (credentials == null) return null;

    final client = _createClient(credentials);

    return _fetchedAccount.fetch(() async {
      final profile = await GetIt.instance
          .get<ApiRepositoryProvider>()
          .getApiRepository(client)
          .getProfileInfo(
              BaseProfileInfo(userId: credentials.userId, login: ''), true);

      return RemoteAccount(
        credential: credentials,
        authType: profile.authType,
        role: profile.role,
        name: profile.login,
        canReceiveMessages: _preferences.onlineChatEnabled,
        pictureUri: profile.pictureUrl,
        client: client,
      );
    });
  }

  @override
  Future<RemoteAccount> signUp(RemoteSignUpData signUpData) =>
      _fetchedAccount.fetch(() => _signUp(signUpData));

  Future<RemoteAccount> _signUp(RemoteSignUpData signUpData) async {
    final response = await _createClient(Credential.empty()).signUp(signUpData);

    final credential =
        Credential(userId: response.userId, accessToken: response.accessToken);

    await _preferences.setCurrentCredentials(credential);

    return RemoteAccount(
      credential: credential,
      name: response.login,
      pictureUri: getPictureUrlOrNull(response.userId, response.pictureHash),
      canReceiveMessages: _preferences.onlineChatEnabled,
      client: _createClient(credential),
      role: response.role,
      authType: response.authType,
    );
  }

  @override
  Future signOut() => _preferences
      .setCurrentCredentials(null)
      .then((_) => _fetchedAccount.invalidate());

  LpsApiClient _createClient(Credential credential) =>
      GetIt.instance.get(param1: credential);
}
