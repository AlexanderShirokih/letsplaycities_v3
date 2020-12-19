import 'package:lets_play_cities/remote/auth.dart';

/// Manages remote accounts
abstract class AccountManager {
  /// Returns last signed in account or `null` if user is not signed in
  RemoteAccountInfo getLastSignedInAccount();

  /// Runs sign in authorization sequence
  Future<RemoteAccountInfo> signIn();

  /// Signs out from the currently logged account
  Future signOut();

  /// Returns `true` if user signed in to any account
  bool isSignedIn();

  /// Updates picture for currently logged account
  Future<void> updatePicture();
}
