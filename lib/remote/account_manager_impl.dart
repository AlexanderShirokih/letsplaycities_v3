import 'package:async/async.dart';

import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/remote_module.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

import 'client/api_client.dart';
import 'account.dart';
import 'account_manager.dart';

class AccountManagerImpl extends AccountManager {
  final GamePreferences _preferences;

  final AsyncCache<RemoteAccount> _fetchedAccount =
      AsyncCache(const Duration(minutes: 5));

  AccountManagerImpl(this._preferences) : assert(_preferences != null);

  @override
  Future<RemoteAccount> getLastSignedInAccount() async {
    var credentials = _preferences.currentCredentials;

    // TODO: Debug
    {
      credentials = Credential(userId: 30955, accessToken: "i'mapass");
    }

    if (credentials == null) return null;

    final client = _createClient(credentials);

    return _fetchedAccount.fetch(() async {
      final profile = await client.getProfileInfo(credentials.userId);

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
    final response = await _createClient(null).signUp(signUpData);

    final credential =
        Credential(userId: response.userId, accessToken: response.accessToken);

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

  LpsApiClient _createClient(Credential credential) => RemoteLpsApiClient(
        getDio(),
        credential,
      );
}
