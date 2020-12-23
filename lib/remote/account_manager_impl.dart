import 'authentication.dart';
import 'account_manager.dart';

/// Test implementation
class AccountManagerImpl extends AccountManager {
  @override
  Future<RemoteAccount> getLastSignedInAccount() async {
    // TODO: Fetch real data
    return RemoteAccount(
      name: 'Test',
      credential: Credential(accessToken: "i'mapass", userId: 30955),
      pictureUri: null,
      canReceiveMessages: false,
    );
  }

  //TODO:
  @override
  Future<RemoteAccount> signIn() => throw ('Unimplemented!');

  // TODO:
  @override
  Future signOut() => throw ('Unimplemented');

  // TODO:
  @override
  bool isSignedIn() => true;
}
