import 'package:lets_play_cities/base/usecases.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';
import 'package:lets_play_cities/remote/model/friend_game_request.dart';

/// Handles game request result.
/// Sends negative result to the server if [RequestResult] is
/// [RequestResult.declined].
/// Throws [AuthorizationException] if user is unauthorized at this stage.
/// Throws [RemoteException] if request sending was failed.
/// Returns [FriendGameRequest?] that contains data to start waiting room
/// or `null`, if nothing should starts.
class HandleRequestResultUseCase
    extends PairedAsyncUseCase<GameRequest, RequestResult, FriendGameRequest?> {
  /// Called only when a decline is sent, so the caller decides which
  /// [AccountManager] is current at that moment.
  final AccountManager Function() _accountManager;

  /// Called only when a decline is sent, like [_accountManager].
  final ApiRepositoryFactory Function() _apiRepositories;

  HandleRequestResultUseCase(this._accountManager, this._apiRepositories);

  @override
  Future<FriendGameRequest?> execute(
    GameRequest request,
    RequestResult result,
  ) async {
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
    final account = await _accountManager().getLastSignedInAccount();

    if (account == null) {
      throw AuthorizationException('Authorization required!');
    }

    await _apiRepositories()
        .forCredential(account.credential)
        .declineGameRequest(requester);
  }
}
