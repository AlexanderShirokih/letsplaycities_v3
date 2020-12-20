import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'authentication/authentication.dart';
import 'account_manager.dart';

/// Test implementation
class StubAccountManager extends AccountManager {
  static const _pictureFile = '/usr_img.png';

  @override
  Future<RemoteAccountInfo> getLastSignedInAccount() async {
    final pictureFile = await _getInternalPictureFile();
    final isPictureExists = await pictureFile.exists();

    return RemoteAccountInfo(
      name: 'Test',
      credential: Credential(accessToken: "i'mapass", userId: 30955),
      pictureUri: isPictureExists ? pictureFile.absolute.path : null,
      canReceiveMessages: false,
    );
  }

  //TODO:
  @override
  Future<RemoteAccountInfo> signIn() => throw ('Unimplemented!');

  // TODO:
  @override
  Future signOut() => throw ('Unimplemented');

  @override
  bool isSignedIn() => true;

  @override
  Future<void> updatePicture(Future<Uint8List> imageData) async {
    // Create thumbnail
    final thumbnail = await createThumbnail(await imageData);

    // Save it in the internal storage
    final pictureFile = await _getInternalPictureFile();
    await pictureFile.writeAsBytes(thumbnail, flush: true);
  }

  @override
  Future<void> removePicture() =>
      _getInternalPictureFile().then((pictureFile) => pictureFile.delete());

  /// Returns path for internal database file
  static Future<File> _getInternalPictureFile() =>
      getApplicationSupportDirectory()
          .then((filesDir) => File(filesDir.path + _pictureFile));
}
