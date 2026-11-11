import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lets_play_cities/main.dart' as app;
import 'package:lets_play_cities/screens/common/design/app_buttons.dart';

/// Cities the player answers with, by the first letter: long ones from many
/// countries, so the score leads and the passport fills up
const _answers = {
  'А': [
    'Александрия',
    'Аддис-Абеба',
    'Амстердам',
    'Архангельск',
    'Астрахань',
    'Анкара',
    'Афины',
  ],
  'Б': ['Барселона', 'Братислава', 'Бухарест', 'Будапешт', 'Барнаул', 'Берлин'],
  'В': ['Владивосток', 'Валенсия', 'Вашингтон', 'Варшава', 'Вильнюс', 'Вена'],
  'Г': ['Гвадалахара', 'Гонолулу', 'Гамбург', 'Гданьск', 'Гродно'],
  'Д': ['Дюссельдорф', 'Днепропетровск', 'Дортмунд', 'Дублин', 'Дели'],
  'Е': ['Екатеринбург', 'Ереван', 'Ессентуки', 'Елец'],
  'Ж': ['Жуковский', 'Женева', 'Житомир'],
  'З': ['Зеленоград', 'Запорожье', 'Загреб', 'Златоуст'],
  'И': ['Индианаполис', 'Иерусалим', 'Иркутск', 'Ижевск', 'Измир'],
  'Й': ['Йошкар-Ола', 'Йоханнесбург', 'Йорк'],
  'К': [
    'Копенгаген',
    'Касабланка',
    'Калининград',
    'Кейптаун',
    'Краснодар',
    'Казань',
    'Каир',
  ],
  'Л': [
    'Лос-Анджелес',
    'Ливерпуль',
    'Лиссабон',
    'Люксембург',
    'Лондон',
    'Липецк',
  ],
  'М': [
    'Монреаль',
    'Марсель',
    'Манчестер',
    'Мельбурн',
    'Мадрид',
    'Милан',
    'Минск',
  ],
  'Н': ['Новосибирск', 'Неаполь', 'Нюрнберг', 'Норильск', 'Нальчик', 'Нарва'],
  'О': ['Оклахома-Сити', 'Оренбург', 'Одесса', 'Оттава', 'Осло', 'Омск'],
  'П': [
    'Петропавловск-Камчатский',
    'Пятигорск',
    'Пекин',
    'Париж',
    'Прага',
    'Пермь',
  ],
  'Р': ['Рио-де-Жанейро', 'Роттердам', 'Рейкьявик', 'Рязань', 'Рига', 'Рим'],
  'С': [
    'Санкт-Петербург',
    'Сан-Франциско',
    'Стокгольм',
    'Сингапур',
    'Сеул',
    'Сочи',
  ],
  'Т': ['Тегусигальпа', 'Таганрог', 'Ташкент', 'Торонто', 'Токио', 'Тула'],
  'У': ['Уссурийск', 'Ульяновск', 'Утрехт', 'Уфа'],
  'Ф': ['Филадельфия', 'Франкфурт', 'Флоренция', 'Феодосия'],
  'Х': ['Хабаровск', 'Хельсинки', 'Хьюстон', 'Херсон'],
  'Ц': ['Цюрих', 'Цхинвали'],
  'Ч': ['Чикаго', 'Челябинск', 'Чебоксары', 'Чита'],
  'Ш': ['Шанхай', 'Штутгарт', 'Шахты'],
  'Щ': ['Щёлково', 'Щецин'],
  'Э': ['Эдинбург', 'Эйндховен', 'Элиста'],
  'Ю': ['Югорск', 'Юрга'],
  'Я': ['Ярославль', 'Якутск', 'Ялта'],
};

/// Walks the app on a clean device and takes the screens for store listings.
///
/// Run on an emulator without accounts:
/// `flutter drive --profile --driver test_driver/integration_test.dart --target integration_test/store_screenshots_test.dart`
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  List<String> texts() => find
      .byType(Text)
      .evaluate()
      .map(
        (e) =>
            (e.widget as Text).data ??
            (e.widget as Text).textSpan?.toPlainText(),
      )
      .whereType<String>()
      .toList();

  void dump(String step) => debugPrint('[$step] ${texts().join(' | ')}');

  Future<void> shot(String name) async {
    await binding.takeScreenshot(name);
  }

  /// The letter the next city has to start with, from the input hint
  String? letter() {
    for (final text in texts()) {
      final match = RegExp(r'^Город на (\S)…$').firstMatch(text);

      if (match != null) return match.group(1);
    }

    return null;
  }

  testWidgets('store screenshots', (tester) async {
    app.main();
    await wait(tester, 8000);
    await binding.convertFlutterSurfaceToImage();
    await wait(tester);
    await shot('01_home');

    await tester.tap(find.text('Играть').first);
    await wait(tester, 4000);

    // First launch shows the rules
    if (find.text('Пропустить').evaluate().isNotEmpty) {
      await tester.tap(find.text('Пропустить'));
      await wait(tester, 3000);
    }

    dump('game');

    final used = <String>{};
    var moves = 0;
    var city = 'Москва';

    for (var attempt = 0; attempt < 40 && moves < 8; attempt++) {
      tester.widget<TextField>(find.byType(TextField).last).controller!.text =
          city;
      await wait(tester, 300);
      await tester.tap(find.byType(AppSquareButton).last);
      await wait(tester, 3500);
      used.add(city);

      final next = letter();
      dump('move $attempt, letter $next');

      if (next == null) break;

      final options = (_answers[next.toUpperCase()] ?? [])
          .where((c) => !used.contains(c))
          .toList();

      if (options.isEmpty) break;

      if (!texts().any((t) => t.contains(city))) {
        // Not accepted: try the next city on the same letter
      } else {
        moves++;
      }

      city = options.first;
    }

    await shot('02_game');

    await tester.tap(find.text('Пауза'));
    await wait(tester);
    await tester.tap(find.text('Сдаться…'));
    await wait(tester);
    await tester.tap(find.text('Сдаться').last);
    await wait(tester, 4000);
    dump('results');
    await shot('03_results');

    await tester.tap(find.text('В меню').last);
    await wait(tester, 3000);
    await tester.tap(find.text('Города').last);
    await wait(tester, 4000);
    dump('cities');
    await shot('04_cities');

    await tester.tap(find.text('Профиль').last);
    await wait(tester, 3000);
    dump('profile');
    await shot('05_profile');
  });
}
