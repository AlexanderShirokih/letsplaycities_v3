import 'package:lets_play_cities/base/usecases.dart';
import 'package:lets_play_cities/remote/api_repository_factory.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';

/// Handles new request logic
class FetchOpponentProfileUseCase
    implements SingleAsyncUseCase<GameRequest, ProfileInfo> {
  final AccountManager _accountManager;

  /// Called when the profile is fetched, so the caller decides which
  /// factory is current at that moment.
  final ApiRepositoryFactory Function() _apiRepositories;

  FetchOpponentProfileUseCase(this._accountManager, this._apiRepositories);

  /// Fetches requester profile.
  /// Throws [AuthorizationException] if user is unauthorized for now
  @override
  Future<ProfileInfo> execute(GameRequest request) async {
    final user = await _accountManager.getLastSignedInAccount();

    if (user == null) {
      throw AuthorizationException('User is unauthorized now');
    }

    if (user.credential.userId != request.targetId) {
      throw WrongAccountException();
    }

    final apiRepository = _apiRepositories().forCredential(user.credential);

    var target = BaseProfileInfo(userId: request.userId, login: request.login);
    return apiRepository.getProfileInfo(target);
  }
}
