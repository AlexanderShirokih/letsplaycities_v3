import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/themes/theme.dart' as theme;
import 'package:lets_play_cities/screens/common/utils.dart';

/// Creates material button with [_text] on center and leading [_icon], if present.
/// Hits [_onTap] when the button is tapped.
class CustomMaterialButton extends StatelessWidget {
  final String _text;
  final Widget? _icon;
  final VoidCallback? _onTap;

  CustomMaterialButton(this._text, [this._icon, this._onTap]);

  @override
  Widget build(BuildContext context) => ElevatedButton(
        style:
            ElevatedButton.styleFrom(primary: Theme.of(context).primaryColor),
        onPressed: _onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              if (_icon != null) Container(width: 20, height: 20, child: _icon),
              Expanded(
                child: Container(
                  alignment: Alignment.center,
                  child: Text(_text.toUpperCase()),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Creates button with icon and ripple effect
class MaterialIconButton extends StatelessWidget {
  final IconData iconData;
  final VoidCallback? onPressed;

  const MaterialIconButton(this.iconData, {required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: IconButton(
          onPressed: onPressed,
          highlightColor: Colors.transparent,
          padding: EdgeInsets.zero,
          color: Theme.of(context).primaryColor,
          icon: Icon(iconData),
        ),
      );
}

/// Creates expanded background image with from theme data
Widget createBackground(BuildContext context) {
  final background = context.watch<theme.Theme>().backgroundImage;
  return background == null
      ? Positioned.fill(child: Container())
      : Positioned.fill(
          child: Image.asset(
            background,
            fit: BoxFit.cover,
          ),
        );
}

/// Shows card with progress bar and message
class LoadingView extends StatelessWidget {
  final String _text;

  LoadingView(this._text);

  @override
  Widget build(BuildContext context) => Center(
        child: Card(
          elevation: 5.0,
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10.0),
                Text(_text, style: Theme.of(context).textTheme.headline6),
              ],
            ),
          ),
        ),
      );
}

/// Shows a snackbar with optional undo action.
/// Calls [onComplete] if it's not null when a snackbar dismissed by timeout.
/// Calls [onUndo] if it's not null when undo button is pressed.
void showUndoSnackbar(BuildContext context, String text,
    {VoidCallback? onComplete, VoidCallback? onUndo}) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Text(text),
          action: readWithLocalization(
            context,
            (l10n) => onComplete == null
                ? null
                : SnackBarAction(
                    label: l10n.cancel,
                    onPressed: onUndo ?? () {},
                  ),
          ),
        ),
      )
      .closed
      .then((reason) {
    if (reason == SnackBarClosedReason.timeout) {
      return onComplete?.call();
    }
  });
}

Widget createStyledMaterialButton(
  BuildContext context,
  Widget icon,
  String text,
  VoidCallback onPressed,
) =>
    ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        elevation: 6.0,
        primary: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      icon: icon,
      label: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(text),
      ),
      onPressed: onPressed,
    );
