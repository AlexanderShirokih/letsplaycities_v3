import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/stt/bloc/voice_recognition_bloc.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

/// Button used to recognize text from speech
/// Requires [VoiceRecognitionBloc] to be provided in widget tree
class VoiceRecognitionButton extends StatelessWidget {
  const VoiceRecognitionButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<VoiceRecognitionBloc, VoiceRecognitionState>(
        builder: (context, state) {
          final c = AppColors.of(context);
          final isListening = state is VoiceRecognitionListening;
          final isReady = isListening || state is VoiceRecognitionReady;

          Widget buildIconButton() => IconButton(
            iconSize: 22,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            padding: EdgeInsets.zero,
            icon: AppIcon(
              AppGlyph.mic,
              size: 22,
              color: isListening ? c.violet : (isReady ? c.inkSoft : c.edge),
            ),
            onPressed: isReady
                ? () => context.read<VoiceRecognitionBloc>().add(
                    VoiceRecognitionToggle(),
                  )
                : null,
          );

          return isListening
              ? AvatarGlow(
                  glowColor: c.violet,
                  duration: const Duration(milliseconds: 1500),
                  repeat: true,
                  child: buildIconButton(),
                )
              : buildIconButton();
        },
      );
}
