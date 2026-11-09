import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Pixel ratio of the shared pictures: 360 logical pixels are 1080 pixels
const double shareImagePixelRatio = 3;

/// Renders [card] of [size] off screen to a PNG named [fileName] in the
/// temporary directory (the file is overwritten) and returns its path.
///
/// The card is put into the overlay of [context], so it inherits the theme and
/// the translations, and is removed as soon as it is captured.
Future<String> renderShareImage(
  BuildContext context,
  Widget card, {
  required Size size,
  required String fileName,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final boundaryKey = GlobalKey();

  // Placed far outside the screen so the user never sees it
  final entry = OverlayEntry(
    builder: (context) => Positioned(
      left: -size.width * 2,
      top: 0,
      width: size.width,
      height: size.height,
      // The picture has a fixed size, so the text must not grow with the
      // system font size
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(key: boundaryKey, child: card),
        ),
      ),
    ),
  );

  overlay.insert(entry);

  try {
    // Wait for the card to be laid out and painted
    await WidgetsBinding.instance.endOfFrame;

    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: shareImagePixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);

    return file.path;
  } finally {
    entry.remove();
    entry.dispose();
  }
}
