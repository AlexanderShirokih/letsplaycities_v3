//@dart=2.9

import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/domain/usecases.dart';
import 'package:lets_play_cities/remote/auth.dart';
import 'package:lets_play_cities/remote/server/usecases.dart';
import 'package:test/test.dart';

void main() {
  SingleUseCase<RemoteSignUpData, ProfileInfo> useCase;

  setUp(() {
    final appConfig = AppConfig.forHost(
      'host',
      isSecure: false,
    );

    useCase = GetProfileInfoFromSignUpData(appConfig);
  });

  RemoteSignUpData buildRequest() => RemoteSignUpData(
        login: 'abc',
        authType: AuthType.Native,
        firebaseToken: 'fbToken',
        accessToken: 'accToken',
        snUID: '1234',
      );

  test('Copies important params from request', () {
    final result = useCase.execute(buildRequest());

    expect(result.login, equals('abc'));
    expect(result.pictureUrl, equals('http://host:8443/user/1234/picture'));
    expect(result.role, equals(Role.regular));
    expect(result.authType, equals(AuthType.Native));
    expect(result.banStatus, equals(BanStatus.notBanned));
    expect(result.friendshipStatus, equals(FriendshipStatus.notFriends));
  });

  test('IDs assigns correctly', () {
    var usedIds = <int>[];

    for (var i = 0; i < 5; i++) {
      final result = useCase.execute(buildRequest());

      expect(result.userId, isPositive);
      expect(usedIds, isNot(contains(result.userId)));

      usedIds.add(result.userId);
    }
  });
}
