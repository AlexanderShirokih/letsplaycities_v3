import 'dart:typed_data';

import 'package:lets_play_cities/base/remote/bloc/avatar_resize_mixin.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Manages remote accounts
abstract class AccountManager with AvatarResizeMixin {
  /// Returns last signed in account or `null` if user is not signed in
  Future<RemoteAccountInfo> getLastSignedInAccount();

  /// Runs sign in authorization sequence
  Future<RemoteAccountInfo> signIn();

  /// Signs out from the currently logged account
  Future signOut();

  /// Returns `true` if user signed in to any account
  bool isSignedIn();

  /// Updates picture for currently logged account
  Future<void> updatePicture(Future<Uint8List> imageData);

  /// Removes user picture from currently logged account
  Future<void> removePicture();
}
