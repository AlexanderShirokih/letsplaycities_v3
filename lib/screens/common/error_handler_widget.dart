import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';

/// A view for showing exceptions
class ErrorHandlerView extends StatefulWidget {
  final String _errorDescription;
  final String _stackTrace;

  const ErrorHandlerView(this._errorDescription, this._stackTrace, {super.key});

  @override
  State<ErrorHandlerView> createState() => _ErrorHandlerViewState();
}

class _ErrorHandlerViewState extends State<ErrorHandlerView> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: D2Card(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              D2Icon(D2Glyph.warning, size: 32, color: c.error),
              const SizedBox(height: 12),
              Text(
                t.errors.crashTitle,
                textAlign: TextAlign.center,
                style: D2Text.title.copyWith(color: c.ink),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      widget._errorDescription,
                      style: D2Text.bodyRegular.copyWith(color: c.ink),
                    ),
                    if (_expanded) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget._stackTrace,
                        style: D2Text.caption.copyWith(color: c.inkSoft),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [
                  D2Button(
                    label: t.d2.details,
                    kind: D2ButtonKind.secondary,
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                  D2Button(
                    label: t.back,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
