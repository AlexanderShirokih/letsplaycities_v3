import 'package:flutter/material.dart';

/// Creates material button with [_text] on center and leading [_icon], if present.
/// Hits [_onTap] when the button is tapped.
class CustomMaterialButton extends StatelessWidget {
  final String _text;
  final Widget _icon;
  final Function _onTap;

  CustomMaterialButton(this._text, [this._icon, this._onTap]);

  @override
  Widget build(BuildContext context) => RaisedButton(
        color: Theme.of(context).accentColor,
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
        onPressed: _onTap,
      );
}

/// Creates button with icon and ripple effect
class MaterialIconButton extends StatelessWidget {
  final IconData iconData;
  final Function onPressed;

  const MaterialIconButton(this.iconData, {this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        child: IconButton(
          onPressed: onPressed,
          highlightColor: Colors.transparent,
          padding: EdgeInsets.zero,
          color: Theme.of(context).primaryColor,
          icon: Icon(iconData),
        ),
      );
}

/// Creates expanded background image with [name] from assets/images/backgrounds directory
Widget createBackground(String name) => Positioned.fill(
      child: Image.asset(
        "assets/images/backgrounds/$name.png",
        key: GlobalKey(),
        fit: BoxFit.cover,
      ),
    );
