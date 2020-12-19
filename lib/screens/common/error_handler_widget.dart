import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lets_play_cities/l18n/localization_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A view for showing exceptions
class ErrorHandlerView extends StatelessWidget {
  final String _errorDescription;
  final String _stackTrace;

  ErrorHandlerView(this._errorDescription, this._stackTrace);

  @override
  Widget build(BuildContext context) => Center(
        child: Card(
          elevation: 5.0,
          margin: EdgeInsets.all(10.0),
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 24.0),
                Text('Ой, кажется произошла ошибка😢',
                    style: Theme.of(context).textTheme.headline6),
                Expanded(
                  child: ListView(
                    children: [
                      Text(_errorDescription,
                          style: Theme.of(context).textTheme.bodyText2),
                      SizedBox(height: 24.0),
                      Text(_stackTrace,
                          style: Theme.of(context).textTheme.bodyText2)
                    ],
                  ),
                ),
                RaisedButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(
                      context.watch<LocalizationService>().back.toUpperCase()),
                ),
              ],
            ),
          ),
        ),
      );
}
