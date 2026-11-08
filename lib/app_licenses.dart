import 'package:flutter/foundation.dart';

const _geonames =
    '''Координаты и сведения о городах: GeoNames (https://www.geonames.org).
Лицензия Creative Commons Attribution 4.0 (CC BY 4.0): https://creativecommons.org/licenses/by/4.0/
Данные изменены: сопоставлены со словарём игры, часть координат уточнена по Wikipedia и Wikidata.''';

const _naturalEarth =
    '''Контур суши на карте: Natural Earth (https://www.naturalearthdata.com).
Данные Natural Earth находятся в общественном достоянии.''';

/// Registers attributions for the bundled geodata (assets/data/geo.bin, world.bin)
/// on the Flutter license page.
void registerDataLicenses() {
  LicenseRegistry.addLicense(
    () => Stream.fromIterable([
      const LicenseEntryWithLineBreaks(['GeoNames'], _geonames),
      const LicenseEntryWithLineBreaks(['Natural Earth'], _naturalEarth),
    ]),
  );
}
