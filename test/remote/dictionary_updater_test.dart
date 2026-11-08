import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/base/dictionary/dictionary_update_period.dart';
import 'package:lets_play_cities/base/dictionary/impl/dictionary_factory.dart';
import 'package:lets_play_cities/base/preferences.dart';
import 'package:lets_play_cities/remote/dictionary_updater.dart';

import '../base/dictionary/impl/dictionary_test_files.dart';

class _FakePrefs implements GamePreferences {
  @override
  DictionaryUpdatePeriod dictionaryUpdatePeriod = DictionaryUpdatePeriod.daily;

  @override
  DateTime lastDictionaryCheckDate = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Answers `/update` with [latestVersion] and `/data-<version>.db2` with
/// [dictionaryResponse], or with 404 when it is `null`.
class _FakeServer implements HttpClientAdapter {
  final int latestVersion;
  final ResponseBody Function()? dictionaryResponse;

  _FakeServer(this.latestVersion, [this.dictionaryResponse]);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/update') {
      return ResponseBody.fromString(
        jsonEncode({
          'dictionary': {'version': latestVersion},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (options.path == '/data-$latestVersion.db2' &&
        dictionaryResponse != null) {
      return dictionaryResponse!();
    }
    return ResponseBody.fromString('', 404);
  }

  @override
  void close({bool force = false}) {}
}

/// Sends [bytes] in four chunks, then fails with [error] if it is given.
ResponseBody _dictionaryBody(
  List<int> bytes, {
  bool withLength = true,
  Object? error,
}) {
  final chunk = (bytes.length / 4).ceil();
  Stream<Uint8List> chunks() async* {
    for (var start = 0; start < bytes.length; start += chunk) {
      final end = start + chunk < bytes.length ? start + chunk : bytes.length;
      yield Uint8List.fromList(bytes.sublist(start, end));
    }
    if (error != null) throw error;
  }

  return ResponseBody(
    chunks(),
    200,
    headers: {
      if (withLength) Headers.contentLengthHeader: ['${bytes.length}'],
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory supportDir;
  late int embeddedVersion;
  late GamePreferences prefs;
  late Dio http;

  File installed() => File('${supportDir.path}/data-last.db2');
  File installedMeta() => File('${supportDir.path}/data-last.db2.meta');

  void serve(int latestVersion, [ResponseBody Function()? dictionary]) {
    http = Dio(BaseOptions(baseUrl: 'https://example.test'))
      ..httpClientAdapter = _FakeServer(latestVersion, dictionary);
  }

  Stream<int> checkForUpdates() =>
      DictionaryUpdater(prefs, http).checkForUpdates();

  Future<List<int>> runUpdate() => checkForUpdates().toList();

  Future<int> installedVersion() async =>
      jsonDecode(await installedMeta().readAsString())['version'];

  /// Installs a previously downloaded dictionary one version newer than the
  /// embedded one and returns its bytes.
  Future<List<int>> installPrevious() async {
    final bytes = buildDictionaryFile(embeddedVersion + 1, {'старгород': 91});
    await installed().writeAsBytes(bytes);
    await installedMeta().writeAsString('{"version": ${embeddedVersion + 1}}');
    return bytes;
  }

  Future<void> expectPreviousKept(List<int> previousBytes) async {
    expect(await installedVersion(), embeddedVersion + 1);
    expect(await installed().readAsBytes(), previousBytes);
    expect(supportDir.listSync().map((e) => e.path), hasLength(2));
    final dictionary = await DictionaryFactory().createDictionary();
    expect(dictionary.getAll().keys, ['старгород']);
  }

  setUp(() async {
    supportDir = await Directory.systemTemp.createTemp('dictionary_updater');
    fakeApplicationSupportDirectory(supportDir);
    embeddedVersion = await embeddedDictionaryVersion();
    DictionaryFactory.invalidateCache();
    prefs = _FakePrefs();
  });

  tearDown(() async {
    DictionaryFactory.invalidateCache();
    fakeApplicationSupportDirectory(null);
    await supportDir.delete(recursive: true);
  });

  test('installs a newer dictionary and reports progress up to 100', () async {
    final version = embeddedVersion + 1;
    serve(
      version,
      () => _dictionaryBody(buildDictionaryFile(version, {'новоград': 91})),
    );

    final progress = await runUpdate();

    expect(progress.first, -1);
    expect(progress.skip(1), everyElement(inInclusiveRange(0, 100)));
    expect(progress.last, 100);
    expect(await installedVersion(), version);
    expect(supportDir.listSync(), hasLength(2)); // no leftovers
    final dictionary = await DictionaryFactory().createDictionary();
    expect(dictionary.getAll().keys, ['новоград']);
  });

  test('reports only 0 and 100 when the server sends no size', () async {
    final version = embeddedVersion + 1;
    serve(
      version,
      () => _dictionaryBody(
        buildDictionaryFile(version, {'новоград': 91}),
        withLength: false,
      ),
    );

    expect(await runUpdate(), [-1, 0, 100]);
    expect(await installedVersion(), version);
  });

  group('keeps the installed dictionary when', () {
    late List<int> previous;
    late List<int> next;

    setUp(() async {
      previous = await installPrevious();
      next = buildDictionaryFile(embeddedVersion + 2, {'новоград': 91});
    });

    test('the dictionary file is missing on the server', () async {
      serve(embeddedVersion + 2);

      await runUpdate();

      await expectPreviousKept(previous);
    });

    test('the connection breaks during the download', () async {
      serve(
        embeddedVersion + 2,
        () => _dictionaryBody(
          next.sublist(0, next.length ~/ 2),
          withLength: false,
          error: const SocketException('Connection reset'),
        ),
      );

      await runUpdate();

      await expectPreviousKept(previous);
    });

    test('the download ends early', () async {
      serve(
        embeddedVersion + 2,
        () => _dictionaryBody(
          next.sublist(0, next.length - 3),
          withLength: false,
        ),
      );

      await runUpdate();

      await expectPreviousKept(previous);
    });

    test('the update is cancelled during the download', () async {
      serve(embeddedVersion + 2, () => _dictionaryBody(next));

      final cancelled = Completer<void>();
      late StreamSubscription<int> subscription;
      subscription = checkForUpdates().listen((percent) {
        // Past 0 a part of the dictionary is already written to disk.
        if (percent > 0) cancelled.complete(subscription.cancel());
      });
      await cancelled.future;

      await expectPreviousKept(previous);
    });

    test(
      'the update of unknown size is cancelled during the download',
      () async {
        final half = next.length ~/ 2;
        final gate = Completer<void>();
        Stream<Uint8List> body() async* {
          yield Uint8List.fromList(next.sublist(0, half));
          await gate.future;
          yield Uint8List.fromList(next.sublist(half));
          // The body never ends, so the update can stop only at a chunk.
          await Completer<void>().future;
        }

        serve(embeddedVersion + 2, () => ResponseBody(body(), 200));

        final subscription = checkForUpdates().listen(null);
        // Once the first chunk is on disk the update is waiting for the next.
        await _waitForLength(File('${installed().path}.download'), half);
        final cancelled = subscription.cancel();
        gate.complete();
        await cancelled.timeout(const Duration(seconds: 5));

        await expectPreviousKept(previous);
      },
    );
  });
}

/// Waits until [file] holds [length] bytes.
Future<void> _waitForLength(File file, int length) async {
  for (var i = 0; i < 500; i++) {
    if (file.existsSync() && file.lengthSync() == length) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('${file.path} never reached $length bytes');
}
