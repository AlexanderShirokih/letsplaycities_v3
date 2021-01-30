import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/remote/model/cloud_messages.dart';

/// Handles new request logic
class FetchOpponentProfileUseCase
    implements SingleAsyncUseCase<GameRequest, ProfileInfo> {
  final AccountManager _accountManager = GetIt.instance.get<AccountManager>();

  FetchOpponentProfileUseCase();

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

    final apiRepository = user.getApiRepository();

    var target = BaseProfileInfo(userId: request.userId, login: request.login);
    return apiRepository.getProfileInfo(target);
  }
}
