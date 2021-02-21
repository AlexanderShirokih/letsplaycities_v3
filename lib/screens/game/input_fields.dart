import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/service_events_bloc.dart';
import 'package:lets_play_cities/base/repos.dart';
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
        child: TextField(
          autofocus: true,
          onSubmitted: _onSubmit,
          textAlignVertical: TextAlignVertical.center,
          controller: inputController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: EdgeInsets.symmetric(
              vertical: 2.0,
              horizontal: 8.0,
            ),
            prefixIcon: VoiceRecognitionButton(
              onWords: _repository.sendInputWord,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: () => _onSubmit(inputController.text),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp("^[А-я-.' ]+\$"),
            )
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
        child: TextField(
          onSubmitted: (text) => _onSubmit(context, text),
          controller: inputController,
          textCapitalization: TextCapitalization.words,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: EdgeInsets.symmetric(
              vertical: 2.0,
              horizontal: 12.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.send),
              onPressed: () => _onSubmit(context, inputController.text),
            ),
            hintText: 'Сообщение',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        ),
      );
}
