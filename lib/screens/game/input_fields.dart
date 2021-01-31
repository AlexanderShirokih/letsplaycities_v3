import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/service_events_bloc.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';
import 'package:lets_play_cities/screens/game/voice_recognition_view.dart';

class InputFieldsGroup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceEventsBloc, ServiceEventsState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: state.isMessageFieldOpened
              ? _ChatMessageInputField()
              : _CityInputField(context.watch<GameSessionRepository>(),
                  context.watch<GameBloc>()),
          transitionBuilder: (child, animation) => ScaleTransition(
            child: child,
            scale: animation,
          ),
        );
      },
    );
  }
}

typedef InputMatcherCallback = void Function(String);

/// Input field for entering cities
class _CityInputField extends StatefulWidget {
  final GameSessionRepository _repository;
  final GameBloc _gameBloc;

  _CityInputField(this._repository, this._gameBloc);

  @override
  _CityInputFieldState createState() =>
      _CityInputFieldState(_repository, _gameBloc);
}

class _CityInputFieldState extends State<_CityInputField> {
  final InputMatcherCallback _onPressed;
  final GameSessionRepository _repository;
  final inputController = TextEditingController();

  _CityInputFieldState(GameSessionRepository repository, GameBloc bloc)
      : _onPressed = repository.sendInputWord,
        _repository = repository {
    // Register callback hook to be able to clear input when the word is accepted.
    bloc.onUserInputAccepted = _onClear;
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
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(8.0),
        color: Colors.white,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            VoiceRecognitionButton(
              onWords: _repository.sendInputWord,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TextField(
                  onSubmitted: _onSubmit,
                  controller: inputController,
                  cursorColor: Theme.of(context).primaryColor,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(border: InputBorder.none),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp("^[А-я-.' ]+\$"),
                    )
                  ],
                ),
              ),
            ),
            MaterialIconButton(
              Icons.add_circle_outline,
              onPressed: () => _onSubmit(inputController.text),
            ),
          ],
        ),
      );

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }
}

/// Used to enter chat messages
class _ChatMessageInputField extends StatefulWidget {
  const _ChatMessageInputField({Key? key}) : super(key: key);

  @override
  __ChatMessageInputFieldState createState() => __ChatMessageInputFieldState();
}

class __ChatMessageInputFieldState extends State<_ChatMessageInputField> {
  final inputController = TextEditingController();

  void _onSubmit(BuildContext context, String value) {
    if (value.isNotEmpty) {
      context.read<GameSessionRepository>().sendChatMessage(value);
      context
          .read<ServiceEventsBloc>()
          .add(ServiceEventsEvent.ToggleMessageField);
      inputController.clear();
    }
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(8.0),
        color: Colors.white,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 0.0, 4.0, 0.0),
                child: TextField(
                  onSubmitted: (text) => _onSubmit(context, text),
                  controller: inputController,
                  cursorColor: Theme.of(context).primaryColor,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Сообщение',
                  ),
                ),
              ),
            ),
            MaterialIconButton(
              Icons.send,
              onPressed: () => _onSubmit(context, inputController.text),
            ),
          ],
        ),
      );
}
