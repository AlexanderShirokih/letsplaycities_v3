import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

List<int> _resizeAndEncode(Uint8List imageData) {
  var image = decodeImage(imageData);
  if (image == null) {
    throw 'Cannot decode image!';
  }
  var thumbnail = copyResizeCropSquare(image, 128);
  return encodePng(thumbnail);
}

mixin AvatarResizeMixin {
  /// Creates thumbnail in the separate [Isolate]
  Future<List<int>> createThumbnail(Uint8List imageData) {
    return compute<Uint8List, List<int>>(_resizeAndEncode, imageData);
  }
}
