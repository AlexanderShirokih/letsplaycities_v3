import 'package:lets_play_cities/remote/auth.dart';

/// Manages remote accounts
abstract class AccountManager {
  /// Returns last signed in account or `null` if user is not signed in
  Future<RemoteAccount> getLastSignedInAccount();

  /// Runs sign in authorization sequence
  Future<RemoteAccount> signIn();

  /// Signs out from the currently logged account
  Future signOut();

  /// Returns `true` if user signed in to any account
  bool isSignedIn();
}
