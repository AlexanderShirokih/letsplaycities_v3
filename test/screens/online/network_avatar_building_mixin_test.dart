import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/remote/model/profile_info.dart';
import 'package:lets_play_cities/screens/online/network_avatar_building_mixin.dart';

class _AvatarBuilder with NetworkAvatarBuildingMixin {}

void main() {
  const initialsByLogin = {
    'Иван Петров': 'ИП',
    'Саша ': 'С',
    ' Саша': 'С',
    'Jean - Luc': 'JL',
    'Анна-Мария': 'АМ',
    'a--b': 'AB',
    '-a': 'A',
    ' ': '?',
    '-': '?',
    '': '?',
  };

  for (final MapEntry(key: login, value: initials) in initialsByLogin.entries) {
    testWidgets('a text avatar for "$login" shows "$initials"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _AvatarBuilder().buildAvatar(
            BaseProfileInfo(userId: 1, login: login),
          ),
        ),
      );

      expect(find.text(initials), findsOneWidget);
    });
  }
}
