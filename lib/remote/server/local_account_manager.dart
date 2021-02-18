import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/client/api_client.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

class LocalAccountManager implements AccountManager {
  final GamePreferences _preferences;
  final LpsApiClient _lpsApiClient;

  LocalAccountManager(this._preferences, this._lpsApiClient);

  @override
  Future<RemoteAccount?> getLastSignedInAccount() async {
    final name = _preferences.lastNativeLogin.isNotEmpty
        ? _preferences.lastNativeLogin
        : 'Игрок';

    final response = await _lpsApiClient.signUp(
      RemoteSignUpData(
        authType: AuthType.Native,
        login: name,
        firebaseToken: '',
        accessToken: '',
        snUID: '',
      ),
    );

    return RemoteAccount(
      credential: Credential(
        userId: response.userId,
        accessToken: response.accessToken,
      ),
      name: response.login,
      pictureUri: null,
      canReceiveMessages: _preferences.onlineChatEnabled,
      role: response.role,
      authType: response.authType,
    );
  }

  @override
  Future<void> signOut() => Future.value();

  @override
  Future<RemoteAccount> signUp(RemoteSignUpData signInData) {
    throw RemoteException('Unsupported operation!');
  }
}
