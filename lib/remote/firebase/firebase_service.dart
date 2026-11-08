import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/cloud_messaging_service.dart';
import 'package:lets_play_cities/utils/error_logger.dart';
import 'package:rxdart/subjects.dart';

/// Provides FCM message handling logic
class FirebaseServices implements CloudMessagingService {
  /// Creates an instance that needs [configure] before it can be used.
  FirebaseServices(this._logger);

  /// Creates an instance that is already configured with [messaging].
  @visibleForTesting
  FirebaseServices.withMessaging(FirebaseMessaging messaging, this._logger)
    : _firebaseMessaging = messaging;

  final ErrorLogger _logger;

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

    // Not awaited: the request completes only when the user answers the dialog.
    unawaited(
      _firebaseMessaging!.requestPermission().then(
        (_) {},
        onError: (Object e, StackTrace s) => _logger.error(e, s),
      ),
    );

    var initialMsg = await _firebaseMessaging!.getInitialMessage();

    if (initialMsg != null) {
      handlePush(initialMsg.data);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handlePush(event.data);
    });
    FirebaseMessaging.onMessage.listen((event) {
      handlePush(event.data);
    });
  }

  /// Returns firebase cloud messaging token, or an empty string when the
  /// token cannot be obtained.
  @override
  Future<String> getUserToken() async {
    if (_firebaseMessaging == null) {
      throw 'Firebase messaging is not initialized!';
    }

    try {
      // TODO: replace getToken() once the server can send to an installation
      // ID. register()/onRegistered yield a Firebase Installation ID instead
      // of the FCM registration token the server sends pushes to today, so
      // switching changes what sign-up and the game login send the server.
      // ignore: deprecated_member_use
      return await _firebaseMessaging!.getToken() ?? '';
    } catch (e, s) {
      // Fails without Google Play services or when FCM is unreachable. The
      // token is optional: without it the user only gets no push messages.
      _logger.error(e, s);
      return '';
    }
  }

  /// Throws when the instance is not configured yet.
  @override
  Stream<String> get tokenRefreshes {
    final messaging = _firebaseMessaging;
    if (messaging == null) {
      throw StateError('Firebase messaging is not initialized!');
    }

    // The same token as getUserToken() returns, see the TODO there.
    // ignore: deprecated_member_use
    return messaging.onTokenRefresh;
  }

  /// Turns the data of a push into a message; pushes of other kinds are
  /// logged and dropped.
  @visibleForTesting
  void handlePush(Map<String, dynamic> data) {
    final request = GameRequest.tryParse(data);

    if (request != null) {
      _inputMessages.add(request);
    } else {
      _logger.log('Received unknown push: ${data['type']}');
    }
  }
}
