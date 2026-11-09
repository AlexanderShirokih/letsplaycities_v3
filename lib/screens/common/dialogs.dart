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
            // Full width, so that the buttons go to the right edge
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 4,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
