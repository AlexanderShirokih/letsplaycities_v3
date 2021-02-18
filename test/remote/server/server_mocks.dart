import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';

final ProfileInfo testProfile = ProfileInfo(
  userId: 123,
  login: 'test',
  pictureUrl: 'http://test',
  role: Role.regular,
  lastVisitDate: DateTime.now(),
  banStatus: BanStatus.notBanned,
  friendshipStatus: FriendshipStatus.friends,
  authType: AuthType.Native,
);
