import 'package:lets_play_cities/remote/model/cloud_messages.dart';

/// Describes interface for receiving messages from remote service
abstract class CloudMessagingService {
  /// Returns stream that emits [IncomingCloudMessage] when got
  /// a new incoming message
  Stream<IncomingCloudMessage> get messages;

  /// Returns user identifier to send messages to him
  Future<String> getUserToken();
}

// Stub implementation used for testing purposes on desktop
class StubCloudMessagingService implements CloudMessagingService {
  @override
  Future<String> getUserToken() {
    return Future.value('desktop');
  }

  @override
  Stream<IncomingCloudMessage> get messages => Stream.empty();
}
