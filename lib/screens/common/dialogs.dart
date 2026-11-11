import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

typedef ConfirmationCallback = void Function(bool isOk);

/// Creates confirmation dialog with a [title], an optional [message] and two
/// buttons: [cancelLabel] (no by default) and [confirmLabel] (yes by default).
/// The confirm button is red when the action is [destructive].
/// To handle only yes event you should pass [onOk] callback.
/// To handle both yes and no events pass [callback].
/// Returns future also containing selected result.
/// May return `null` if user pressed outside the dialog.
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  VoidCallback? onOk,
  ConfirmationCallback? callback,
}) => showDialog<bool>(
  context: context,
  barrierColor: AppColors.of(context).shadow.withValues(alpha: 0.55),
  builder: (BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);

    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppText.display.copyWith(fontSize: 20, color: c.ink),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: AppText.bodyRegular.copyWith(
                      fontSize: 16,
                      height: 1.4,
                      color: c.inkSoft,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DialogButton(
                    label: cancelLabel ?? t.no,
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      callback?.call(false);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: confirmLabel ?? t.yes,
                    confirm: true,
                    destructive: destructive,
                    onPressed: () {
                      Navigator.of(context).pop(true);
                      if (onOk != null) {
                        onOk();
                      } else {
                        callback?.call(true);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);

/// Dialog button: a soft one for cancel, an outlined one with a hard shadow
/// for confirm
class _DialogButton extends StatelessWidget {
  final String label;
  final bool confirm;
  final bool destructive;
  final VoidCallback onPressed;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.confirm = false,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fill = !confirm ? c.bg : (destructive ? c.error : c.orange);
    final fg = !confirm ? c.ink : (destructive ? Colors.white : c.ink);
    final radius = BorderRadius.circular(16);
    final style = confirm ? AppText.cta.copyWith(fontSize: 15) : AppText.body;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.only(bottom: confirm ? 4 : 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: confirm ? Border.all(color: c.shadow, width: 2) : null,
            boxShadow: confirm
                ? [BoxShadow(color: c.shadow, offset: const Offset(0, 4))]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label, style: style.copyWith(color: fg)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
