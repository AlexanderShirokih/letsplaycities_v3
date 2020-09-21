import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:lets_play_cities/screens/common/utils.dart';

typedef ConfirmationCallback(bool isOk);
typedef OnOkCallback();

/// Creates confirmation dialog which can show title(optional), message(requires)
/// and has two buttons(yes, no).
/// To handle only yes event you should pass [onOk] callback.
/// To handle both yes and no events pass [callback].
/// Returns future also containing selected result.
/// May contain null if user pressed outside the dialog.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  String title,
  @required String message,
  OnOkCallback onOk,
  ConfirmationCallback callback,
}) =>
    showDialog(
      context: context,
      builder: (BuildContext context) => withLocalization(
        context,
        (l10n) => AlertDialog(
          title: title == null ? null : Text(title),
          content: Text(message),
          actions: [
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                callback?.call(false);
              },
              child: Text(l10n.no.toUpperCase()),
            ),
            FlatButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                if (onOk != null)
                  onOk();
                else
                  callback?.call(true);
              },
              child: Text(l10n.yes.toUpperCase()),
            ),
          ],
          elevation: 20.0,
        ),
      ),
    );

/// Shows single choice dialog that can show list of items and cancel button.
/// When user taps on item according index will returned.
/// If no items was selected `null` will be emitted.
Future<int> showSingleChoiceDialog(BuildContext context, String title,
        List<String> choices, int currentChoice) =>
    showDialog(
        context: context,
        builder: (context) =>
            SingleChoiceDialog(title, choices, currentChoice));

class SingleChoiceDialog extends StatefulWidget {
  final String _title;
  final List<String> _choicesList;
  final int _currentChoice;

  SingleChoiceDialog(this._title, this._choicesList, this._currentChoice);

  @override
  _SingleChoiceDialogState createState() =>
      _SingleChoiceDialogState(_title, _choicesList, _currentChoice);
}

class _SingleChoiceDialogState extends State<SingleChoiceDialog> {
  final String _title;
  final List<String> _choicesList;
  int _selectedItemId = 0;

  _SingleChoiceDialogState(this._title, this._choicesList, int currentChoice)
      : _selectedItemId = currentChoice;

  @override
  Widget build(BuildContext context) => AlertDialog(
        contentPadding: EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 0.0),
        title: Text(_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Iterable.generate(_choicesList.length, (i) => i)
              .map(
                (int index) => RadioListTile(
                  title: Text(_choicesList[index]),
                  value: index,
                  groupValue: _selectedItemId,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedItemId = newValue;
                    });
                    Future.microtask(
                            () => Future.delayed(Duration(milliseconds: 300)))
                        .then((_) => Navigator.of(context).pop(newValue));
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          FlatButton(
            onPressed: () => Navigator.of(context).pop(),
            child: withLocalization(
                context, (l10n) => Text(l10n.cancel.toUpperCase())),
          )
        ],
      );
}
