import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lets_play_cities/themes/theme.dart' as theme;

/// Creates material button with [_text] on center and leading [_icon], if present.
/// Hits [_onTap] when the button is tapped.
class CustomMaterialButton extends StatelessWidget {
  final String _text;
  final Widget _icon;
  final Function _onTap;

  CustomMaterialButton(this._text, [this._icon, this._onTap]);

  @override
  Widget build(BuildContext context) => RaisedButton(
        color: Theme.of(context).primaryColor,
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

/// Creates expanded background image with from theme data
Widget createBackground(BuildContext context) => Positioned.fill(
      child: Image.asset(
        context.repository<theme.Theme>().backgroundImage,
        fit: BoxFit.cover,
      ),
    );

/// Shows card with progress bar and message
class LoadingView extends StatelessWidget {
  final String _text;

  LoadingView(this._text) : assert(_text != null);

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

/// Loads flag image from assets for [countryCode]
Image createFlagImage(int countryCode) => Image.asset(
      "assets/images/flags/flag_$countryCode.png",
      height: 20.0,
    );
