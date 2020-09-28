import 'authentication/authentication.dart';
import 'account_manager.dart';

/// Test implementation
class StubAccountManager extends AccountManager {
  @override
  RemoteAccountInfo getLastSignedInAccount() => RemoteAccountInfo(
        name: 'Alexander Shirokikh(test)',
        credential: Credential(accessToken: '*ok3W(vW', userId: 54),
        pictureUri: null,
        canReceiveMessages: false,
      );

  //TODO:
  @override
  Future<RemoteAccountInfo> signIn() => throw ('Unimplemented!');

  @override
  bool isSignedIn() => true;
}
