import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/utils.dart';

/// Creates [ProfileInfo] from [RemoteSignUpData]
class GetProfileInfoFromSignUpData
    implements SingleUseCase<RemoteSignUpData, ProfileInfo> {
  // Keeps temporary IDs of authorized users
  var _tempId = 0;

  final AppConfig _appConfig;

  GetProfileInfoFromSignUpData(this._appConfig);

  @override
  ProfileInfo execute(RemoteSignUpData request) => ProfileInfo(
        // remote ID used as snUID
        pictureUrl: request.snUID.isNotEmpty
            ? getPictureUrlOrNullNoHash(_appConfig, request.snUID)
            : null,
        userId: ++_tempId,
        login: request.login,
        role: Role.regular,
        lastVisitDate: DateTime.now(),
        banStatus: BanStatus.notBanned,
        friendshipStatus: FriendshipStatus.notFriends,
        authType: AuthType.Native,
      );
}
