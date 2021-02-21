import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';

class LocalAccountManager implements AccountManager {
  final GamePreferences _preferences;
  final AccountManager _mainAccountManager;
  final SingleAsyncUseCase<RemoteSignUpData, RemoteSignUpResponse>
      _signUpUseCase;

  LocalAccountManager(
    this._mainAccountManager,
    this._preferences,
    this._signUpUseCase,
  );

  @override
  Future<RemoteAccount?> getLastSignedInAccount() async {
    // First try to fetch remote profile info
    final remoteAccount = await _mainAccountManager
        .getLastSignedInAccount()
        .timeout(Duration(seconds: 5), onTimeout: () => null);

    late RemoteSignUpData signUpData;

    if (remoteAccount != null) {
      signUpData = RemoteSignUpData(
        authType: AuthType.Native,
        login: remoteAccount.name,
        firebaseToken: '',
        accessToken: 'native_access',
        // we passing remote ID as snUID
        snUID: remoteAccount.credential.userId.toString(),
      );
    } else {
      signUpData = RemoteSignUpData(
        authType: AuthType.Native,
        login: _preferences.lastNativeLogin.isNotEmpty
            ? _preferences.lastNativeLogin
            : 'Игрок',
        firebaseToken: '',
        accessToken: '',
        snUID: '',
      );
    }

    final response = await _signUpUseCase.execute(signUpData);

    return RemoteAccount(
      credential: Credential(
        userId: response.userId,
        accessToken: response.accessToken,
      ),
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
