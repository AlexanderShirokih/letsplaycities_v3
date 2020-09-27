import 'package:lets_play_cities/remote/auth.dart';

/// Manages remote accounts
abstract class AccountManager {
  /// Returns last signed in account or `null` if user is not signed in
  RemoteAccountInfo getLastSignedInAccount();

  Future<RemoteAccountInfo> signIn();

  /// Returns `true` if user signed in to any account
  bool isSignedIn();
}
