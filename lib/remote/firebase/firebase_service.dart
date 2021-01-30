// ignore: import_of_legacy_library_into_null_safe
import 'dart:async';

// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_core/firebase_core.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/utils/error_logger.dart';

/// Provides FCM message handling logic
class FirebaseServices implements CloudMessagingService {
  FirebaseServices._();

  static final FirebaseServices _instance = FirebaseServices._();

  final ErrorLogger _logger = GetIt.instance.get<ErrorLogger>();

  /// Returns singleton FCM instance
  static FirebaseServices get instance => _instance;

  FirebaseMessaging? _firebaseMessaging;

  final StreamController<IncomingCloudMessage> _inputMessages =
      StreamController.broadcast();

  @override
  Stream<IncomingCloudMessage> get messages => _inputMessages.stream;

  Future<void> configure() async {
    if (_firebaseMessaging != null) {
      return;
    }

    await Firebase.initializeApp();

    _firebaseMessaging = FirebaseMessaging.instance;

    var initialMsg =
        await (_firebaseMessaging!.getInitialMessage()) as RemoteMessage?;

    if (initialMsg != null) {
      _handleAction(initialMsg.data);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      _handleAction(event.data);
    });
    FirebaseMessaging.onMessage.listen((event) {
      _handleAction(event.data);
    });
  }

  /// Returns firebase cloud messaging token
  @override
  Future<String> getUserToken() {
    if (_firebaseMessaging == null) {
      throw 'Firebase messaging is not initialized!';
    }

    return _firebaseMessaging!.getToken();
  }

  void _handleAction(Map<String, dynamic> data) {
    final action = data['action'];

    // We got a valid action
    if (action != null) {
      // Action type is friend-mode request
      if (action == 'fm_request') {
        _instance._inputMessages.add(GameRequest.fromMap(data));
      } else {
        _logger.log('Received unknown remote action: ${action}');
      }
    } else {
      _logger.log('Got remote message, but action is null!');
    }
  }

  // TODO: REMOVE AFTER TESTS
  @override
  void addTestEvent() {
    _inputMessages.add(GameRequest('Stepik Depic 3000!', 12341, 14476));
  }
}
