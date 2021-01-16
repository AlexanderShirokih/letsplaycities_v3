import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/account_manager_impl.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Manages remote accounts
abstract class AccountManager {
  /// Returns last signed in account or `null` if user is not signed in
  Future<RemoteAccount?> getLastSignedInAccount();

  /// Runs sign in authorization sequence
  Future<RemoteAccount> signUp(RemoteSignUpData signInData);

  /// Signs out from the currently logged account
  Future signOut();

  const AccountManager();

  static AccountManager? _cached;

  factory AccountManager.fromPreferences(GamePreferences prefs) {
    return (_cached ??= AccountManagerImpl(prefs));
  }
}
