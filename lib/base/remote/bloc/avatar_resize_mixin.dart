import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

mixin AvatarResizeMixin {
  /// Creates thumbnail in the separate [Isolate]
  Future<List<int>> createThumbnail(Uint8List imageData) {
    return compute<Uint8List, List<int>>((Uint8List imageData) {
      var thumbnail = copyResizeCropSquare(decodeImage(imageData), 128);
      return encodePng(thumbnail);
    }, imageData);
  }
}
