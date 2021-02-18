import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';

/// Creates [ProfileInfo] from [RemoteSignUpData]
class GetProfileInfoFromSignUpData
    implements SingleUseCase<RemoteSignUpData, ProfileInfo> {
  // Keeps temporary IDs of authorized users
  var _tempId = 0;

  @override
  ProfileInfo execute(RemoteSignUpData request) => ProfileInfo(
        userId: ++_tempId,
        login: request.login,
        pictureUrl: '',
        role: Role.regular,
        lastVisitDate: DateTime.now(),
        banStatus: BanStatus.notBanned,
        friendshipStatus: FriendshipStatus.notFriends,
        authType: AuthType.Native,
      );
}
