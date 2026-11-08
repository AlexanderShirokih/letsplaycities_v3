import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_config.dart';
import 'package:lets_play_cities/remote/model/history_info.dart';

void main() {
  final config = AppConfig.forHost(
    'pictures.test',
    port: 8080,
    isSecure: false,
  );

  Map<String, dynamic> json({String isFriend = 'true', String? hash}) => {
    'userId': 3,
    'login': 'Bob',
    'isFriend': isFriend,
    'duration': 95,
    'wordsCount': 12,
    'startTime': 1700000000000,
    'pictureHash': hash,
  };

  test('fromJson reads the fields and builds the picture URL from the config '
      'it is given', () {
    final record = HistoryInfo.fromJson(config, json(hash: 'abc'));

    expect(record.userId, 3);
    expect(record.login, 'Bob');
    expect(record.isFriend, isTrue);
    expect(record.duration, 95);
    expect(record.wordsCount, 12);
    expect(
      record.startTime,
      DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );
    expect(
      record.pictureUrl,
      'http://pictures.test:8080/user/3/picture?hash=abc',
    );
  });

  test('fromJson reads isFriend "false" as not a friend', () {
    expect(
      HistoryInfo.fromJson(config, json(isFriend: 'false')).isFriend,
      isFalse,
    );
  });

  test('fromJson leaves the picture URL empty without a picture hash', () {
    expect(HistoryInfo.fromJson(config, json()).pictureUrl, isNull);
    expect(HistoryInfo.fromJson(config, json(hash: '')).pictureUrl, isNull);
  });
}
