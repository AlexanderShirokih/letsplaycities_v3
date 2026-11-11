import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';

/// Two letter tiles hopping one after another and a message under them
class LoadingView extends StatefulWidget {
  final String _text;

  const LoadingView(this._text, {super.key});

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  static const _cycle = Duration(milliseconds: 1100);

  /// Delay of the second tile as a part of the cycle: 0.22 s of 1.1 s
  static const _delay = 0.2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  );

  /// Up for the first 28% of the cycle, down until 55%, then at rest
  static final _hop = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: -16.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 28,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: -16.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 27,
    ),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 45),
  ]);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _tile(String letter, AppTileColor color, double angle, double phase) =>
      AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, _hop.transform((_controller.value - phase) % 1)),
          child: child,
        ),
        child: Transform.rotate(
          angle: angle * pi / 180,
          child: ExcludeSemantics(
            child: AppLetterTile(letter, size: 58, height: 62, color: color),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    // Material: the view is also shown with no Scaffold above it, where the
    // text would get the debug style on a black background
    return Material(
      color: c.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 86,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _tile('Г', AppTileColor.white, -6, 0),
                  const SizedBox(width: 10),
                  _tile('А', AppTileColor.orange, 5, _delay),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  widget._text,
                  textAlign: TextAlign.center,
                  style: AppText.body.copyWith(color: c.inkSoft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a snackbar with optional undo action.
/// Calls [onComplete] if it's not null when a snackbar dismissed by timeout.
/// Calls [onUndo] if it's not null when undo button is pressed.
void showUndoSnackbar(
  BuildContext context,
  String text, {
  VoidCallback? onComplete,
  VoidCallback? onUndo,
}) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          // A snackbar with an action never times out by default, and
          // [onComplete] runs only on timeout.
          persist: false,
          content: Text(text),
          action: onComplete == null
              ? null
              : SnackBarAction(
                  label: context.t.cancel,
                  onPressed: onUndo ?? () {},
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
) => ElevatedButton.icon(
  style: ElevatedButton.styleFrom(
    elevation: 6.0,
    backgroundColor: Theme.of(context).primaryColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  ),
  icon: icon,
  label: Padding(padding: const EdgeInsets.all(16.0), child: Text(text)),
  onPressed: onPressed,
);
