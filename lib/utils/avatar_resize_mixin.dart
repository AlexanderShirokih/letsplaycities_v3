import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

/// Side of the avatar that the server accepts from the client, in pixels
const avatarSize = 256;

Uint8List _resizeAndEncode(Uint8List imageData) {
  var image = decodeImage(imageData);
  if (image == null) {
    throw 'Cannot decode image!';
  }
  var avatar = copyResizeCropSquare(image, size: avatarSize);
  return Uint8List.fromList(encodePng(avatar));
}

mixin AvatarResizeMixin {
  /// Scales the image to a [avatarSize] square PNG in a separate [Isolate]
  Future<Uint8List> createAvatarPng(Uint8List imageData) {
    return compute<Uint8List, Uint8List>(_resizeAndEncode, imageData);
  }
}
