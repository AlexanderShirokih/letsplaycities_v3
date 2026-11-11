import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/settings/licenses_screen.dart';

import '../../i18n/translations_harness.dart';

void main() {
  testWidgets('lists the packages by name and opens their texts', (
    tester,
  ) async {
    final licenses = Stream<LicenseEntry>.fromIterable([
      const LicenseEntryWithLineBreaks(['zeta'], 'Zeta license'),
      const LicenseEntryWithLineBreaks(['alpha', 'zeta'], 'Shared license'),
    ]);

    await tester.pumpWidget(
      withTranslations(
        MaterialApp(
          theme: buildAppTheme(Brightness.light),
          home: LicensesScreen(licenses: licenses),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final alpha = tester.getTopLeft(find.text('alpha'));
    final zeta = tester.getTopLeft(find.text('zeta'));
    expect(alpha.dy, lessThan(zeta.dy));
    expect(find.textContaining('Flutter'), findsNothing);

    await tester.tap(find.text('zeta'));
    await tester.pumpAndSettle();

    expect(find.text('Zeta license'), findsOneWidget);
    expect(find.text('Shared license'), findsOneWidget);
  });
}
