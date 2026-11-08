import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';

/// A view for showing exceptions
class ErrorHandlerView extends StatelessWidget {
  final String _errorDescription;
  final String _stackTrace;

  const ErrorHandlerView(this._errorDescription, this._stackTrace, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Center(
      child: Card(
        elevation: 5.0,
        margin: EdgeInsets.all(10.0),
        child: Container(
          padding: EdgeInsets.all(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 24.0),
              Text(
                t.errors.crashTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      _errorDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 24.0),
                    Text(
                      _stackTrace,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.maybePop(context),
                child: Text(t.back.toUpperCase()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
