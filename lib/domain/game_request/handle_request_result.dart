import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/data/models/friend_game_request.dart';
import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/account_manager.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';

/// Handles game request result.
/// Sends negative result to the server if [RequestResult] is
/// [RequestResult.declined].
/// Throws [AuthorizationException] if user is unauthorized at this stage.
/// Throws [RemoteException] if request sending was failed.
/// Returns [FriendGameRequest?] that contains data to start waiting room
/// or `null`, if nothing should starts.
class HandleRequestResultUseCase
    extends PairedAsyncUseCase<GameRequest, RequestResult, FriendGameRequest?> {
  @override
  Future<FriendGameRequest?> execute(
      GameRequest request, RequestResult result) async {
    switch (result) {
      case RequestResult.accepted:
        // Request accepted, start the network game
        return _createRequest(request);
      case RequestResult.declined:
        // Request declined, send result to the server
        await _sendNegativeResult(request.requester);
        return null;
    }
  }

  FriendGameRequest _createRequest(GameRequest request) => FriendGameRequest(
        target: request.requester,
        mode: FriendGameRequestType.join,
      );

  Future<void> _sendNegativeResult(BaseProfileInfo requester) async {
    final accountManager = GetIt.instance.get<AccountManager>();
    final account = await accountManager.getLastSignedInAccount();

    if (account == null) {
      throw AuthorizationException('Authorization required!');
    }

    await account.getApiRepository().declineGameRequest(requester);
  }
}
