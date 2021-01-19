import 'package:lets_play_cities/base/data.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

/// Gate for local API server in remote game mode
/// Provides game server logic for two users.
abstract class RemoteApiServer {
  /// Starts the server.
  /// Returns Future that completes when server has started.
  Future<void> startServer();

  /// Waits for opponent to be connected and returns its data.
  Future<ProfileInfo> awaitOpponent();

  /// Closes the server connection
  Future<void> close();

  /// Sends [city] to client
  /// [wordResult] result of word validation
  /// [city] input city
  /// [ownerId] ID of user who sends this city
  Future<void> sendCity(WordResult wordResult, String city, int ownerId);

  /// Sends [message] to client
  /// [message] message
  /// [ownerId] ID of user who sends this message
  Future<void> sendMessage(String message, int ownerId);
}
