import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/voice_recognition_view.dart';

import 'city_checking_result_bar.dart';

/// Bottom panel with the city input field, the «Send» button and the result
/// of the word checking under them.
class InputFieldsGroup extends StatelessWidget {
  const InputFieldsGroup({super.key});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: c.edge)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14),
        child: _CityInputField(
          context.watch<GameSessionRepository>(),
          context.watch<GameBloc>(),
        ),
      ),
    );
  }
}

typedef InputMatcherCallback = void Function(String);

/// Input field for entering cities
class _CityInputField extends StatefulWidget {
  final GameSessionRepository _repository;
  final GameBloc _gameBloc;

  const _CityInputField(this._repository, this._gameBloc);

  @override
  State<_CityInputField> createState() => _CityInputFieldState();
}

class _CityInputFieldState extends State<_CityInputField> {
  late final InputMatcherCallback _onPressed;
  final inputController = TextEditingController();
  final _errorShown = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _onPressed = widget._repository.sendInputWord;
    // Register callback hook to be able to clear input when the word is accepted.
    widget._gameBloc.onUserInputAccepted = _onClear;
  }

  void _onSubmit(String value) {
    if (value.isNotEmpty) {
      _onPressed(value);
    }
  }

  void _onClear() {
    inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _errorShown,
                builder: (context, error, child) => Container(
                  height: 56,
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  decoration: BoxDecoration(
                    color: error ? c.surface : c.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: error ? Border.all(color: c.error, width: 2) : null,
                  ),
                  child: child,
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTextField(c)),
                    const VoiceRecognitionButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            D2SquareButton(
              D2Glyph.send,
              tooltip: context.t.game.send,
              onPressed: () => _onSubmit(inputController.text),
            ),
          ],
        ),
        CityCheckingResultBar(errorShown: _errorShown),
      ],
    );
  }

  Widget _buildTextField(D2Colors c) => TextField(
    // No context menu: pasting city names is not allowed.
    contextMenuBuilder: null,
    autofocus: true,
    onSubmitted: _onSubmit,
    controller: inputController,
    textCapitalization: TextCapitalization.words,
    cursorColor: c.violet,
    style: D2Text.body.copyWith(fontSize: 19, color: c.ink),
    decoration: const InputDecoration(
      isCollapsed: true,
      border: InputBorder.none,
    ),
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp("^[А-я-.' ]+\$")),
    ],
  );

  @override
  void dispose() {
    inputController.dispose();
    _errorShown.dispose();
    super.dispose();
  }
}
