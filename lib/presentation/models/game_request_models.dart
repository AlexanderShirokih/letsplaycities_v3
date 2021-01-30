import 'package:equatable/equatable.dart';
import 'package:lets_play_cities/data/models/friend_game_request.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:meta/meta.dart';

/// Marker class for game request data models
@sealed
abstract class BaseGameRequestData {}

/// Model that describes new input request
class GotInputGameRequest extends BaseGameRequestData with EquatableMixin {
  final GameRequest rawRequest;
  final ProfileInfo requester;

  GotInputGameRequest(this.rawRequest, this.requester);

  @override
  List<Object?> get props => [rawRequest, requester];
}

/// Models used when request was processed with positive result
class GameRequestProcessingResult extends BaseGameRequestData
    with EquatableMixin {
  final FriendGameRequest request;

  GameRequestProcessingResult(this.request);

  @override
  List<Object?> get props => [request];
}
