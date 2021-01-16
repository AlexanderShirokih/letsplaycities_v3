import 'dart:typed_data';

import 'package:flutter/foundation.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:image/image.dart';

List<int> _resizeAndEncode(Uint8List imageData) {
  var thumbnail = copyResizeCropSquare(decodeImage(imageData), 128);
  return encodePng(thumbnail);
}

mixin AvatarResizeMixin {
  /// Creates thumbnail in the separate [Isolate]
  Future<List<int>> createThumbnail(Uint8List imageData) {
    return compute<Uint8List, List<int>>(_resizeAndEncode, imageData);
  }
}
