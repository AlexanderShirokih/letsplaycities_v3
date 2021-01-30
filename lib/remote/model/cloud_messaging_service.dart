import 'package:lets_play_cities/remote/model/cloud_messages.dart';

/// Describes interface for receiving messages from remote service
abstract class CloudMessagingService {
  /// Returns stream that emits [IncomingCloudMessage] when got
  /// a new incoming message
  Stream<IncomingCloudMessage> get messages;

  /// Returns user identifier to send messages to him
  Future<String> getUserToken();
}
