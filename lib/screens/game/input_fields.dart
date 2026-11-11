import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/voice_recognition_view.dart';

import 'city_checking_result_bar.dart';
import 'hotseat_handoff.dart';

/// Bottom panel with the city input field, the «Send» button and the result
/// of the word checking under them. When the panel gets less height than it
/// needs, the result scrolls.
///
/// Requires [GameSessionRepository] and [GameServiceEventsRepository].
class InputFieldsGroup extends StatelessWidget {
  /// Receives the callback that clears the field when the word is accepted
  final ValueSetter<VoidCallback> onRegisterInputClear;

  const InputFieldsGroup({super.key, required this.onRegisterInputClear});

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
          onRegisterInputClear,
        ),
      ),
    );
  }
}

typedef InputMatcherCallback = void Function(String);

/// Input field for entering cities
class _CityInputField extends StatefulWidget {
  final GameSessionRepository _repository;
  final ValueSetter<VoidCallback> _onRegisterInputClear;

  const _CityInputField(this._repository, this._onRegisterInputClear);

  @override
  State<_CityInputField> createState() => _CityInputFieldState();
}

class _CityInputFieldState extends State<_CityInputField> {
  late final InputMatcherCallback _onPressed;
  final inputController = TextEditingController();
  final _focus = FocusNode();
  final _errorShown = ValueNotifier(false);
  late final StreamSubscription<String> _firstChars;

  /// First letter of the move, empty before the first move
  String _letter = '';

  bool _covered = false;

  @override
  void initState() {
    super.initState();
    _onPressed = widget._repository.sendInputWord;
    // Register callback hook to be able to clear input when the word is accepted.
    widget._onRegisterInputClear(_onClear);
    _firstChars = context
        .read<GameServiceEventsRepository>()
        .getFirstChars()
        .listen((letter) => setState(() => _letter = letter));
  }

  // The next player is ready to type once the handoff cover goes away.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final covered = HotseatHandoff.isCovering(context);
    if (_covered && !covered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
    _covered = covered;
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
        Flexible(
          child: SingleChildScrollView(
            child: CityCheckingResultBar(errorShown: _errorShown),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(D2Colors c) {
    final t = context.t;
    final style = D2Text.body.copyWith(fontSize: 19, color: c.ink);

    return TextField(
      // No context menu: pasting city names is not allowed.
      contextMenuBuilder: null,
      // No keyboard hints: the answer must be typed, not autocompleted.
      autocorrect: false,
      enableSuggestions: false,
      autofocus: true,
      focusNode: _focus,
      onSubmitted: _onSubmit,
      controller: inputController,
      textCapitalization: TextCapitalization.words,
      cursorColor: c.violet,
      style: style,
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: _letter.isEmpty
            ? t.game.cityHint
            : t.game.cityOnLetterHint(letter: _letter.toUpperCase()),
        hintStyle: style.copyWith(color: c.inkSoft),
        hintMaxLines: 1,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp("^[А-я-.' ]+\$")),
      ],
    );
  }

  @override
  void dispose() {
    _firstChars.cancel();
    inputController.dispose();
    _focus.dispose();
    _errorShown.dispose();
    super.dispose();
  }
}
