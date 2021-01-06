import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/client/remote_api_client.dart';
import 'package:lets_play_cities/remote/remote_module.dart';

import 'client/api_client.dart';
import 'account.dart';
import 'account_manager.dart';

class AccountManagerImpl extends AccountManager {
  final GamePreferences _preferences;

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

    // TODO: Save current name and picture URI or fetch fresh profile info
    return RemoteAccount(
      name: 'User #${credentials.userId}',
      credential: credentials,
      client: client,
      pictureUri: null,
      canReceiveMessages: false,
    );
  }

  @override
  Future<RemoteAccount> signIn(RemoteSignInData signInData) =>
      _createClient(null).signUp(signInData);

  @override
  Future signOut() => _preferences.setCurrentCredentials(null);

  LpsApiClient _createClient(Credential credential) => RemoteLpsApiClient(
        getDio(),
        credential,
      );
}
