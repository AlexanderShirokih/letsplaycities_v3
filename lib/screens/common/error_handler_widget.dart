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
    const mono = TextStyle(
      fontFamily: 'Menlo',
      fontFamilyFallback: ['monospace', 'Courier'],
      fontSize: 12,
      height: 1.5,
    );

    return D2EmptyState(
      art: D2TileArt(glyph: D2Glyph.warning, tileColor: c.yellow),
      title: t.errors.crashTitle,
      text: t.errors.crashHint,
      extra: _expanded
          ? Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 148),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: c.edge, offset: const Offset(0, 3)),
                ],
              ),
              child: SingleChildScrollView(
                child: Text.rich(
                  TextSpan(
                    style: mono.copyWith(color: c.ink),
                    children: [
                      TextSpan(text: widget._errorDescription),
                      TextSpan(
                        text: '\n${widget._stackTrace}',
                        style: TextStyle(color: c.inkSoft),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
            )
          : null,
      actionLabel: t.back,
      actionIcon: D2Glyph.back,
      onAction: () => Navigator.maybePop(context),
      secondaryAction: Semantics(
        expanded: _expanded,
        child: D2Button(
          label: _expanded ? t.errors.hideDetails : t.d2.details,
          kind: D2ButtonKind.secondary,
          size: D2ButtonSize.large,
          expand: true,
          onPressed: () => setState(() => _expanded = !_expanded),
        ),
      ),
    );
  }
}
