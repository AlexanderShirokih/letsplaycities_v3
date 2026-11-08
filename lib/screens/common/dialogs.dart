import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';

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

    return _D2Dialog(
      title: title,
      content: Text(
        message,
        style: D2Text.bodyRegular.copyWith(color: D2Colors.of(context).ink),
      ),
      actions: [
        D2Button(
          label: t.no.toUpperCase(),
          kind: D2ButtonKind.secondary,
          onPressed: () {
            Navigator.of(context).pop(false);
            callback?.call(false);
          },
        ),
        D2Button(
          label: t.yes.toUpperCase(),
          onPressed: () {
            Navigator.of(context).pop(true);
            if (onOk != null) {
              onOk();
            } else {
              callback?.call(true);
            }
          },
        ),
      ],
    );
  },
);

/// Dialog shell: radius 24, Unbounded title, buttons in a row
class _D2Dialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget> actions;

  const _D2Dialog({this.title, required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: D2Text.title.copyWith(color: c.ink)),
              const SizedBox(height: 12),
            ],
            Flexible(child: SingleChildScrollView(child: content)),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 12,
              runSpacing: 4,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }
}

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
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return _D2Dialog(
      title: widget._title,
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
                  contentPadding: EdgeInsets.zero,
                  activeColor: c.violet,
                  title: Text(
                    widget._choicesList[index],
                    style: D2Text.body.copyWith(color: c.ink),
                  ),
                  value: index,
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        D2Button(
          label: context.t.cancel.toUpperCase(),
          kind: D2ButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
