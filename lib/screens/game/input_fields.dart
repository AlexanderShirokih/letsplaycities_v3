import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/game/bloc/game_bloc.dart';
import 'package:lets_play_cities/base/repos.dart';
import 'package:lets_play_cities/screens/common/common_widgets.dart';

class InputFieldsGroup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CityInputField(
        context.repository<GameSessionRepository>(), context.bloc<GameBloc>());
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
  final inputController = TextEditingController();

  _CityInputFieldState(GameSessionRepository repository, GameBloc bloc)
      : _onPressed = repository.sendInputWord {
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
            const MaterialIconButton(Icons.keyboard_voice),
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
