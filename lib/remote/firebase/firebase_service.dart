import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/utils/error_logger.dart';
import 'package:rxdart/subjects.dart';

/// Provides FCM message handling logic
class FirebaseServices implements CloudMessagingService {
  FirebaseServices._();

  static final FirebaseServices _instance = FirebaseServices._();

  final ErrorLogger _logger = GetIt.instance.get<ErrorLogger>();

  /// Returns singleton FCM instance
  static FirebaseServices get instance => _instance;

  FirebaseMessaging? _firebaseMessaging;

  final _inputMessages = BehaviorSubject<IncomingCloudMessage>();

  @override
  Stream<IncomingCloudMessage> get messages => _inputMessages.stream;

  Future<void> configure() async {
    if (_firebaseMessaging != null) {
      return;
    }

    await Firebase.initializeApp();

    _firebaseMessaging = FirebaseMessaging.instance;

    var initialMsg = await _firebaseMessaging!.getInitialMessage();

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
  Future<String> getUserToken() async {
    if (_firebaseMessaging == null) {
      throw 'Firebase messaging is not initialized!';
    }

    final token = await _firebaseMessaging!.getToken();
    return token ?? '';
  }

  void _handleAction(Map<String, dynamic> data) {
    final action = data['action'];

    // We got a valid action
    if (action != null) {
      // Action type is friend-mode request
      if (action == 'fm_request') {
        _instance._inputMessages.add(GameRequest.fromMap(data));
      } else {
        _logger.log('Received unknown remote action: $action');
      }
    } else {
      _logger.log('Got remote message, but action is null!');
    }
  }
}
