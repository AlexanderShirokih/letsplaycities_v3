import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/model/blacklist_item_info.dart';

void main() {
  final config = AppConfig.forHost(
    'pictures.test',
    port: 8080,
    isSecure: false,
  );

  test('fromJson reads the fields and builds the picture URL from the config '
      'it is given', () {
    final item = BlackListItemInfo.fromJson(config, {
      'userId': 4,
      'login': 'Eve',
      'pictureHash': 'abc',
    });

    expect(item.userId, 4);
    expect(item.login, 'Eve');
    expect(
      item.pictureUrl,
      'http://pictures.test:8080/user/4/picture?hash=abc',
    );
  });

  test('fromJson leaves the picture URL empty without a picture hash', () {
    BlackListItemInfo parse(String? hash) => BlackListItemInfo.fromJson(
      config,
      {'userId': 4, 'login': 'Eve', 'pictureHash': hash},
    );

    expect(parse(null).pictureUrl, isNull);
    expect(parse('').pictureUrl, isNull);
  });
}
