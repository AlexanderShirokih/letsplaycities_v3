import 'package:flutter/material.dart';

/// Creates material button with [text] on center and leading [icon], if present.
/// Hits [onTap] when the button is tapped.
Widget createButton(BuildContext context, String text,
    [Widget icon, Function onTap]) {
  return RaisedButton(
    color: Theme.of(context).accentColor,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          if (icon != null) Container(width: 20, height: 20, child: icon),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: Text(text.toUpperCase()),
            ),
          ),
        ],
      ),
    ),
    onPressed: onTap,
  );
}
