import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Plays sound from assets [assetSoundPath] when [windowStream] event emits.
///
/// [assetSoundPath] is relative to the `assets/` directory.
class SoundPlayer extends StatefulWidget {
  final String assetSoundPath;
  final Stream<dynamic> windowStream;

  const SoundPlayer({
    super.key,
    required this.assetSoundPath,
    required this.windowStream,
  });

  @override
  State<SoundPlayer> createState() => _SoundPlayerState();
}

class _SoundPlayerState extends State<SoundPlayer> {
  final AudioPlayer _player = AudioPlayer();

  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _player.setPlayerMode(PlayerMode.lowLatency);
    // A short click must not take audio focus on Android: that pauses the
    // user's background music for the rest of the game.
    _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
      ),
    );
    _subscription = widget.windowStream
        .asyncMap((_) => _playAsset())
        .listen(null);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAsset() => _player.play(AssetSource(widget.assetSoundPath));

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
