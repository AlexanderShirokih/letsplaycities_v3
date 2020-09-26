import 'dart:async';

import 'package:audioplayers/audio_cache.dart';
import 'package:flutter/widgets.dart';

/// Plays sound from assets [assetSoundPath] when [windowStream] event emits
class SoundPlayer extends StatefulWidget {
  final AudioCache _cache = AudioCache();
  final String assetSoundPath;
  final Stream<dynamic> windowStream;

  SoundPlayer({@required this.assetSoundPath, @required this.windowStream})
      : assert(assetSoundPath != null),
        assert(windowStream != null);

  @override
  _SoundPlayerState createState() =>
      _SoundPlayerState(_cache, assetSoundPath, windowStream);
}

class _SoundPlayerState extends State<SoundPlayer> {
  final AudioCache _cache;
  final String _assetSoundPath;
  final Stream<dynamic> _windowStream;

  StreamSubscription _subscription;

  _SoundPlayerState(this._cache, this._assetSoundPath, this._windowStream);

  @override
  void initState() {
    super.initState();
    _subscription = _windowStream.asyncMap((_) => _playAsset()).listen(null);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future _playAsset() => _cache.play(_assetSoundPath);

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
