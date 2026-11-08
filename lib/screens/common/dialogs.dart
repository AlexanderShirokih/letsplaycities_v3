import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

typedef ConfirmationCallback = void Function(bool isOk);

/// Creates confirmation dialog which can show title(optional), message(requires)
/// and has two buttons(yes, no).
/// To handle only yes event you should pass [onOk] callback.
/// To handle both yes and no events pass [callback].
/// Returns future also containing selected result.
/// May return `null` if user pressed outside the dialog.
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  String? title,
  required String message,
  VoidCallback? onOk,
  ConfirmationCallback? callback,
}) => showDialog<bool>(
  context: context,
  builder: (BuildContext context) {
    final t = context.t;
    return AlertDialog(
      title: title == null ? null : Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            callback?.call(false);
          },
          child: Text(t.no.toUpperCase()),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            if (onOk != null) {
              onOk();
            } else {
              callback?.call(true);
            }
          },
          child: Text(t.yes.toUpperCase()),
        ),
      ],
      elevation: 20.0,
    );
  },
);

/// Shows single choice dialog that can show list of items and cancel button.
/// When user taps on item according index will returned.
/// If no items was selected `null` will be emitted.
Future<int?> showSingleChoiceDialog(
  BuildContext context,
  String title,
  List<String> choices,
  int currentChoice,
) => showDialog(
  context: context,
  builder: (context) => SingleChoiceDialog(title, choices, currentChoice),
);

class SingleChoiceDialog extends StatefulWidget {
  final String _title;
  final List<String> _choicesList;
  final int _currentChoice;

  const SingleChoiceDialog(
    this._title,
    this._choicesList,
    this._currentChoice, {
    super.key,
  });

  @override
  State<SingleChoiceDialog> createState() => _SingleChoiceDialogState();
}

class _SingleChoiceDialogState extends State<SingleChoiceDialog> {
  late int _selectedItemId;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _selectedItemId = widget._currentChoice;
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    contentPadding: EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 0.0),
    title: Text(widget._title),
    content: RadioGroup<int>(
      groupValue: _selectedItemId,
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() {
            _selectedItemId = newValue;
          });
          _closeTimer?.cancel();
          _closeTimer = Timer(Duration(milliseconds: 300), () {
            // Once the dialog is closing (Cancel, barrier tap, back) it stays
            // mounted during its exit animation, and pop() would close the
            // route underneath it instead.
            if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
              Navigator.of(context).pop(newValue);
            }
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: Iterable.generate(widget._choicesList.length, (i) => i)
            .map(
              (int index) => RadioListTile<int>(
                title: Text(widget._choicesList[index]),
                value: index,
              ),
            )
            .toList(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.t.cancel.toUpperCase()),
      ),
    ],
  );
}
