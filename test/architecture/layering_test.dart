// Checks the dependency direction between the layers of `lib/`.
//
// The rules are data: change [_layerRules], [_allowedImports] or
// [_getItLayers], not the test bodies.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _package = 'lets_play_cities';

enum Layer {
  l0('L0'),
  core('CORE'),
  i18n('I18N'),
  remote('REMOTE'),
  bloc('BLOC'),
  ui('UI'),
  root('ROOT');

  const Layer(this.label);

  final String label;
}

/// Assigns every file under `lib/` to a layer. The first matching rule wins,
/// so the bloc rule has to come before the general `lib/base` rule.
final _layerRules = <(Layer, RegExp)>[
  (Layer.root, RegExp(r'^lib/(main|local_debug_main|app_injection|app_licenses)\.dart$')),
  (Layer.l0, RegExp(r'^lib/(utils/.+|app_config\.dart)$')),
  (Layer.bloc, RegExp(r'^lib/base/(.+/)?bloc/.+$')),
  (Layer.core, RegExp(r'^lib/base/.+$')),
  // Generated typed strings (slang).
  (Layer.i18n, RegExp(r'^lib/i18n/.+$')),
  (Layer.remote, RegExp(r'^lib/remote/.+$')),
  (Layer.ui, RegExp(r'^lib/screens/.+$')),
];

/// Layers each layer may import from.
const _allowedImports = <Layer, Set<Layer>>{
  Layer.l0: {Layer.l0},
  Layer.core: {Layer.core, Layer.l0},
  Layer.i18n: {Layer.i18n, Layer.core, Layer.l0},
  Layer.remote: {Layer.remote, Layer.core, Layer.l0},
  Layer.bloc: {Layer.bloc, Layer.core, Layer.remote, Layer.l0},
  Layer.ui: {
    Layer.ui,
    Layer.bloc,
    Layer.core,
    Layer.i18n,
    Layer.remote,
    Layer.l0,
  },
  Layer.root: {...Layer.values},
};

/// Layers that may import `package:get_it`.
const _getItLayers = {Layer.root, Layer.ui};

/// `part of` is left out: it names the library the file belongs to.
final _directive = RegExp(
  r'''^\s*(?:import|export|part(?!\s+of\b))\s+([^;]+);''',
  multiLine: true,
);
final _quotedUri = RegExp(r'''['"]([^'"]+)['"]''');

/// A `lib/` Dart file with the URIs of its import, export and part
/// directives, including conditional imports.
class _SourceFile {
  _SourceFile(this.path, this.uris);

  final String path;
  final List<String> uris;

  Layer? get layer => _layerOf(path);

  /// Imported `lib/` paths of this package.
  Iterable<String> get localTargets =>
      uris.map((uri) => _resolveLocal(path, uri)).whereType<String>();

  bool get importsGetIt => uris.any((uri) => uri.startsWith('package:get_it/'));
}

Layer? _layerOf(String path) {
  for (final (layer, pattern) in _layerRules) {
    if (pattern.hasMatch(path)) return layer;
  }
  return null;
}

/// Returns the `lib/`-relative path [uri] points to, or `null` for SDK and
/// third-party imports.
String? _resolveLocal(String fromPath, String uri) {
  const prefix = 'package:$_package/';
  if (uri.startsWith(prefix)) return 'lib/${uri.substring(prefix.length)}';
  if (uri.contains(':')) return null;
  return Uri.parse(fromPath).resolve(uri).path;
}

List<_SourceFile> _scanLib() {
  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .map((file) {
            final path = file.path.replaceAll(r'\', '/');
            final uris = [
              for (final directive in _directive.allMatches(
                file.readAsStringSync(),
              ))
                for (final uri in _quotedUri.allMatches(directive.group(1)!))
                  uri.group(1)!,
            ];
            return _SourceFile(path, uris);
          })
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return files;
}

String _labels(Iterable<Layer> layers) =>
    layers.map((layer) => layer.label).join(', ');

void main() {
  final files = _scanLib();

  test('scans the lib/ directory', () {
    expect(
      files.length,
      greaterThan(100),
      reason: 'Run the tests from the package root so that lib/ is found.',
    );
  });

  test('every lib/ file belongs to a layer', () {
    final unassigned = [
      for (final file in files)
        if (file.layer == null) file.path,
    ];
    expect(
      unassigned,
      isEmpty,
      reason:
          'These files match no rule in _layerRules. Move them into a '
          'layer directory or add a rule for them:\n'
          '${unassigned.join('\n')}',
    );
  });

  test('imports follow the layer table', () {
    final violations = <String>[];
    for (final file in files) {
      final from = file.layer;
      if (from == null) continue;
      final allowed = _allowedImports[from]!;
      for (final target in file.localTargets) {
        final to = _layerOf(target);
        if (to != null && allowed.contains(to)) continue;
        violations.add(
          '${file.path} [${from.label}] imports $target '
          '[${to?.label ?? 'no layer'}]; ${from.label} may import only '
          '${_labels(allowed)}',
        );
      }
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Lower layers must not depend on higher ones. Move the shared code '
          'down a layer, or pass it in from the caller:\n'
          '${violations.join('\n')}',
    );
  });

  test('only screens and the root import the generated strings', () {
    final strings = _layerOf('lib/i18n/strings.g.dart');
    expect(strings, Layer.i18n);
    expect(
      [
        for (final MapEntry(key: layer, value: allowed)
            in _allowedImports.entries)
          if (allowed.contains(strings)) layer,
      ],
      unorderedEquals([Layer.i18n, Layer.ui, Layer.root]),
      reason:
          'lib/base, lib/remote and lib/utils take texts as values or '
          'through interfaces such as ExclusionMessages; the screens fill '
          'them from the generated strings.',
    );
  });

  test('package:get_it is imported only from '
      '${_labels(_getItLayers)} files', () {
    final violations = [
      for (final file in files)
        if (file.importsGetIt && !_getItLayers.contains(file.layer))
          '${file.path} [${file.layer?.label ?? 'no layer'}]',
    ];
    expect(
      violations,
      isEmpty,
      reason:
          'These files use the service locator outside '
          '${_labels(_getItLayers)}. Take the dependencies as constructor '
          'parameters and resolve them where the screen creates the object:\n'
          '${violations.join('\n')}',
    );
  });
}
