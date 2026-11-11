import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves the screenshots the integration tests take into `build/screenshots`
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('build/screenshots/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    return true;
  },
);
