import 'package:flutter/services.dart';

/// The share class provides capabilities to share users score
/// with platform-specific sharing dialogs
class Share {
  static const MethodChannel _shareChannel =
      MethodChannel('ru.aleshi.letsplaycities/share');

  /// Share plain text with other apps
  static Future<void> text(String text) =>
      _shareChannel.invokeMethod('share_text', {'text': text});
}
