import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/exceptions.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';

void main() {
  final t = AppLocale.ru.buildSync();
  const accessDenied =
      'У вас нет доступа к получению информации. Возможно истек срок жизни '
      'токенов доступа. Попробуйте очистить данные приложения';

  group('authorizationErrorText', () {
    test('explains a refused access', () {
      expect(authorizationErrorText(t, AccessDeniedException()), accessDenied);
    });

    test('shows the reason of other failures as it came', () {
      expect(
        authorizationErrorText(t, AuthorizationException('Banned')),
        'Banned',
      );
    });
  });

  group('errorText', () {
    test('shows a refused access in words for the player', () {
      expect(errorText(t, AccessDeniedException()), accessDenied);
    });

    test('shows other errors as they describe themselves', () {
      final error = FetchingException('timeout', Uri.parse('https://lps'));

      expect(errorText(t, error), error.toString());
    });
  });
}
