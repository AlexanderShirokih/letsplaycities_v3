// ignore: import_of_legacy_library_into_null_safe
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/presentation/blocs/voice_recognition_bloc.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';

/// Button used to recognize text from speech
/// Requires [GameBloc] to be injected in widget tree
class VoiceRecognitionButton extends StatelessWidget {
  final void Function(String) onWords;

  const VoiceRecognitionButton({
    Key? key,
    required this.onWords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameBloc = context.watch<GameBloc>();
    final voiceRecognitionBloc = VoiceRecognitionBloc(onWords);
    // Register callback hook to be able to clear input when the word is accepted.
    gameBloc.onUserMoveBegins = () {
      voiceRecognitionBloc.add(VoiceRecognitionAutoBegin());
    };

    return BlocProvider<VoiceRecognitionBloc>.value(
      value: voiceRecognitionBloc..add(VoiceRecognitionInit()),
      child: BlocBuilder<VoiceRecognitionBloc, VoiceRecognitionState>(
        builder: (context, state) {
          final isListening = state is VoiceRecognitionListening;
          final isReady = isListening || state is VoiceRecognitionReady;

          return AvatarGlow(
            animate: isListening,
            endRadius: 24.0,
            glowColor: Theme.of(context).primaryColor,
            duration: const Duration(milliseconds: 1500),
            repeatPauseDuration: const Duration(milliseconds: 100),
            repeat: true,
            child: MaterialIconButton(
              Icons.mic,
              onPressed: isReady
                  ? () => context
                      .read<VoiceRecognitionBloc>()
                      .add(VoiceRecognitionToggle())
                  : null,
            ),
          );
        },
      ),
    );
  }
}
