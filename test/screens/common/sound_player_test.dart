import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lets_play_cities/screens/common/sound_player.dart';

const _codec = StandardMethodCodec();

void main() {
  testWidgets('click sound does not take audio focus on Android', (
    tester,
  ) async {
    final playerCalls = <MethodCall>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    // Answers every audioplayers platform call (players, event channels,
    // global init) with success and records the per-player ones.
    messenger.allMessagesHandler = (channel, handler, message) async {
      if (channel == 'xyz.luan/audioplayers') {
        playerCalls.add(_codec.decodeMethodCall(message));
      }
      return _codec.encodeSuccessEnvelope(null);
    };
    addTearDown(() => messenger.allMessagesHandler = null);

    await tester.pumpWidget(
      const SoundPlayer(
        assetSoundPath: 'sound/click.mp3',
        windowStream: Stream.empty(),
      ),
    );
    await tester.pumpAndSettle();

    final contexts = playerCalls.where((c) => c.method == 'setAudioContext');
    expect(contexts, hasLength(1));
    expect(
      (contexts.single.arguments as Map)['audioFocus'],
      AndroidAudioFocus.none.value,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
