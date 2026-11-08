import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/base/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

class LocalAccountManager implements AccountManager {
  final GamePreferences _preferences;
  final AccountManager _mainAccountManager;
  final SingleAsyncUseCase<RemoteSignUpData, RemoteSignUpResponse>
  _signUpUseCase;

  /// Login of a native account when the user has not entered one yet.
  final String _defaultLogin;

  LocalAccountManager(
    this._mainAccountManager,
    this._preferences,
    this._signUpUseCase,
    this._defaultLogin,
  );

  @override
  Future<RemoteAccount?> getLastSignedInAccount() async {
    // First try to fetch remote profile info. A local game often runs on a
    // network without internet access, so any failure there falls back to a
    // native account, just like a slow response does.
    RemoteAccount? remoteAccount;
    try {
      remoteAccount = await _mainAccountManager
          .getLastSignedInAccount()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      remoteAccount = null;
    }

    late RemoteSignUpData signUpData;

    if (remoteAccount != null) {
      signUpData = RemoteSignUpData(
        authType: AuthType.native,
        login: remoteAccount.name,
        firebaseToken: '',
        accessToken: 'native_access',
        // we passing remote ID as snUID
        snUID: remoteAccount.userId.toString(),
      );
    } else {
      signUpData = RemoteSignUpData(
        authType: AuthType.native,
        login: _preferences.lastNativeLogin.isNotEmpty
            ? _preferences.lastNativeLogin
            : _defaultLogin,
        firebaseToken: '',
        accessToken: '',
        snUID: '',
      );
    }

    final response = await _signUpUseCase.execute(signUpData);

    return RemoteAccount(
      userId: response.userId,
      name: response.login,
      pictureUri: (remoteAccount?.picture as NetworkPictureSource?)?.pictureURL,
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
