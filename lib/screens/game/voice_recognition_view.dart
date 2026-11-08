import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';

/// Button used to recognize text from speech
/// Requires [VoiceRecognitionBloc] to be provided in widget tree
class VoiceRecognitionButton extends StatelessWidget {
  const VoiceRecognitionButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<VoiceRecognitionBloc, VoiceRecognitionState>(
        builder: (context, state) {
          final isListening = state is VoiceRecognitionListening;
          final isReady = isListening || state is VoiceRecognitionReady;

          Widget buildIconButton() => IconButton(
            icon: Icon(Icons.mic),
            onPressed: isReady
                ? () => context.read<VoiceRecognitionBloc>().add(
                    VoiceRecognitionToggle(),
                  )
                : null,
          );

          return isListening
              ? AvatarGlow(
                  glowColor: Theme.of(context).colorScheme.secondary,
                  duration: const Duration(milliseconds: 1500),
                  repeat: true,
                  child: buildIconButton(),
                )
              : buildIconButton();
        },
      );
}
