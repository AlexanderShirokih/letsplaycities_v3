// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_core/firebase_core.dart';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles FCM message handling logic
class FirebaseServices {
  FirebaseServices._();

  static final FirebaseServices _instance = FirebaseServices._();

  /// Returns singleton FCM instance
  static FirebaseServices get instance => _instance;

  FirebaseMessaging? _firebaseMessaging;

  /// Gate function for receiving background messages
  static Future<void> _fcmBackgroundMessageHandler(
    RemoteMessage message,
  ) async {
    // TODO: Implement logic!
    print('FCM MESSAGE!:: $message');
  }

  Future<void> configure() async {
    if (_firebaseMessaging != null) {
      return;
    }

    await Firebase.initializeApp();
    _firebaseMessaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundMessageHandler);
    FirebaseMessaging.onMessage.listen((event) {
      // TODO: Handle logic!
      print('FCM:: onMessage: ${event.data}');
    });
  }

  /// Returns firebase cloud messaging token
  Future<String> getToken() {
    if (_firebaseMessaging == null) {
      throw 'Firebase messaging is not initialized!';
    }

    return _firebaseMessaging!.getToken();
  }
}
