import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/app_licenses.dart';

void main() {
  test('registers the GeoNames and Natural Earth attributions', () async {
    registerDataLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final packages = entries.expand((e) => e.packages).toSet();

    expect(packages, containsAll(<String>['GeoNames', 'Natural Earth']));

    final geonames = entries.firstWhere((e) => e.packages.contains('GeoNames'));
    final text = geonames.paragraphs.map((p) => p.text).join('\n');

    expect(text, contains('CC BY 4.0'));
    expect(text, contains('geonames.org'));
  });
}
