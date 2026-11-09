import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../dictionary.dart';
import '../dictionary/impl/dictionary_factory.dart';
import 'geo_index.dart';
import 'world_outline.dart';

/// Bundled dictionary together with city coordinates and the world outline
class RouteData {
  static const _geoPath = 'assets/data/geo.bin';
  static const _worldPath = 'assets/data/world.bin';

  static RouteData? _cached;
  static WorldOutline? _world;

  final DictionaryService dictionary;
  final GeoIndex geo;
  final WorldOutline world;

  @visibleForTesting
  const RouteData(this.dictionary, this.geo, this.world);

  /// Loads the data once per process, later calls only reset the dictionary
  static Future<RouteData> load() async {
    final cached = _cached;

    if (cached != null) {
      cached.dictionary.reset();

      return cached;
    }

    final embedded = await DictionaryFactory.loadEmbedded();
    final geo = GeoIndex.parse(
      await rootBundle.load(_geoPath),
      embedded.names,
      embedded.version,
    );
    final data = RouteData(embedded.dictionary, geo, await loadWorld());

    return _cached = data;
  }

  /// Loads only the world outline, without touching the dictionary
  static Future<WorldOutline> loadWorld() async {
    return _world ??= WorldOutline.parse(await rootBundle.load(_worldPath));
  }
}
