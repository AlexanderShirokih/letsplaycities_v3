import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/model/friend_info.dart';

void main() {
  final config = AppConfig.forHost(
    'pictures.test',
    port: 8080,
    isSecure: false,
  );

  test('fromJson reads the fields and builds the picture URL from the config '
      'it is given', () {
    final friend = FriendInfo.fromJson(config, {
      'userId': 2,
      'login': 'Alice',
      'accepted': true,
      'sender': false,
      'pictureHash': 'abc',
    });

    expect(friend.userId, 2);
    expect(friend.login, 'Alice');
    expect(friend.accepted, isTrue);
    expect(friend.sender, isFalse);
    expect(
      friend.pictureUrl,
      'http://pictures.test:8080/user/2/picture?hash=abc',
    );
  });

  test('fromJson leaves the picture URL empty without a picture hash', () {
    FriendInfo parse(String? hash) => FriendInfo.fromJson(config, {
      'userId': 2,
      'login': 'Alice',
      'accepted': false,
      'sender': true,
      'pictureHash': hash,
    });

    expect(parse(null).pictureUrl, isNull);
    expect(parse('').pictureUrl, isNull);
  });
}
