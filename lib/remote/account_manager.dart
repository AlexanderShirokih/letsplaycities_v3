import 'package:lets_play_cities/remote/auth.dart';

/// Manages remote accounts
abstract class AccountManager {
  /// Returns last signed in account or `null` if user is not signed in
  Future<RemoteAccount?> getLastSignedInAccount();

  /// Signs in the account of this device without asking the user. Returns
  /// `null` when the device has no account or the server cannot be reached.
  Future<RemoteAccount?> trySilentNative();

  /// Signs in the account of this device, creating it with [name]
  Future<RemoteAccount> signInNative(String name);

  /// Signs in through the social network [type]
  Future<RemoteAccount> signInSocial(AuthType type);

  /// Signs out from the currently logged account
  Future<void> signOut();
}
