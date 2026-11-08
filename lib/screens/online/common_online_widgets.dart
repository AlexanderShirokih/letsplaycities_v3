import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/api_repository.dart';
import 'package:lets_play_cities/remote/model/lps_user.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';

/// Shows widget with error messages
Widget showError(BuildContext context, Object error) {
  final t = context.t;
  return Stack(
    children: [
      SizedBox(height: 10.0, child: ListView()),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: error.toString().isEmpty
                ? [
                    Icon(
                      Icons.wifi_off,
                      size: 64.0,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                    const SizedBox(height: 12),
                    Text(t.online.loadingError),
                  ]
                : [
                    FaIcon(
                      FontAwesomeIcons.bug,
                      size: 64.0,
                      color: Theme.of(context).textTheme.bodySmall!.color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.online.unkError,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(errorText(t, error), textAlign: TextAlign.center),
                  ],
          ),
        ),
      ),
    ],
  );
}

/// Shows loading widget (progress indicatior with loading string)
Widget showLoadingWidget(BuildContext context) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 6.0),
      Text(context.t.online.loading),
    ],
  ),
);

/// «Нет связи с сервером» of D2: the illustration, the title, [errorMessage]
/// or the hint, «Повторить» that runs [onReload] and «В меню».
class ConnectionErrorView extends StatelessWidget {
  final String? errorMessage;
  final void Function() onReload;

  /// Leaves for the main menu; by default pops to the first route
  final VoidCallback? onMenu;

  const ConnectionErrorView({
    super.key,
    required this.onReload,
    this.errorMessage,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ExcludeSemantics(
                          child: FittedBox(child: _NoConnectionArt()),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          t.online.noConnection,
                          textAlign: TextAlign.center,
                          style: D2Text.display.copyWith(
                            fontSize: 24,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          errorMessage ?? t.online.noConnectionHint,
                          textAlign: TextAlign.center,
                          style: D2Text.bodyRegular.copyWith(
                            fontSize: 16,
                            color: c.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              D2Button(
                label: t.online.reload,
                icon: D2Glyph.replay,
                size: D2ButtonSize.large,
                expand: true,
                onPressed: onReload,
              ),
              const SizedBox(height: 14),
              D2Button(
                label: t.online.toMenu,
                icon: D2Glyph.exit,
                kind: D2ButtonKind.secondary,
                size: D2ButtonSize.large,
                expand: true,
                onPressed:
                    onMenu ??
                    () =>
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A phone and the globe of the server with a broken line between them
class _NoConnectionArt extends StatelessWidget {
  const _NoConnectionArt();

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(248, 150),
    painter: _NoConnectionPainter(D2Colors.of(context)),
  );
}

class _NoConnectionPainter extends CustomPainter {
  final D2Colors c;

  const _NoConnectionPainter(this.c);

  /// Always white: on the violet card and on the red mark
  static final _white = D2Colors.light.surface;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..color = c.shadow
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      const Offset(124, 78),
      70,
      Paint()..color = c.surface.withValues(alpha: 0.6),
    );

    _card(canvas, 50, -8, 18, c.surface, outline, (card) {
      card.drawRRect(
        RRect.fromLTRBR(38, 52, 62, 94, const Radius.circular(6)),
        outline,
      );
      card.drawLine(const Offset(47, 88), const Offset(53, 88), outline);
    });

    final globe = Paint()
      ..style = PaintingStyle.stroke
      ..color = _white
      ..strokeWidth = 2.5;
    _card(canvas, 198, 8, 166, c.violet, outline, (card) {
      card.drawCircle(const Offset(198, 74), 20, globe);
      card.drawOval(
        Rect.fromCenter(center: const Offset(198, 74), width: 16.8, height: 40),
        globe,
      );
      card.drawLine(const Offset(178, 74), const Offset(218, 74), globe);
    });

    final dots = Paint()
      ..color = c.shadow
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final x in [88.0, 96.0, 104.0, 144.0, 152.0, 160.0]) {
      canvas.drawPoints(PointMode.points, [Offset(x, 78)], dots);
    }

    canvas.drawCircle(const Offset(124, 81), 16, Paint()..color = c.shadow);
    canvas.drawCircle(const Offset(124, 78), 16, Paint()..color = c.error);
    canvas.drawCircle(const Offset(124, 78), 16, outline);
    final cross = Paint()
      ..color = _white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(118, 72), const Offset(130, 84), cross);
    canvas.drawLine(const Offset(130, 72), const Offset(118, 84), cross);

    canvas.save();
    canvas.translate(118, 22);
    canvas.rotate(18 * pi / 180);
    final tile = RRect.fromLTRBR(-6, -6, 6, 6, const Radius.circular(3));
    canvas.drawRRect(tile, Paint()..color = c.yellow);
    canvas.drawRRect(tile, outline..strokeWidth = 2);
    canvas.restore();

    outline.strokeWidth = 2;
    canvas.drawCircle(const Offset(96, 132), 5, Paint()..color = c.orange);
    canvas.drawCircle(const Offset(96, 132), 5, outline);
    canvas.drawCircle(const Offset(160, 130), 4, Paint()..color = c.surface);
    canvas.drawCircle(const Offset(160, 130), 4, outline);
  }

  /// A card of 64×68 at [left], turned by [degrees] around ([centerX], 78),
  /// with a hard shadow; [content] draws on it.
  void _card(
    Canvas canvas,
    double centerX,
    double degrees,
    double left,
    Color fill,
    Paint outline,
    void Function(Canvas card) content,
  ) {
    canvas.save();
    canvas.translate(centerX, 78);
    canvas.rotate(degrees * pi / 180);
    canvas.translate(-centerX, -78);

    canvas.drawRRect(
      RRect.fromLTRBR(left, 46, left + 64, 114, const Radius.circular(16)),
      Paint()..color = c.shadow,
    );
    final face = RRect.fromLTRBR(
      left,
      40,
      left + 64,
      108,
      const Radius.circular(16),
    );
    canvas.drawRRect(face, Paint()..color = fill);
    canvas.drawRRect(face, outline);
    content(canvas);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_NoConnectionPainter old) => old.c != c;
}

/// Initial of [name] for an avatar without a picture
String nameInitial(String name) =>
    name.isEmpty ? '' : name.characters.first.toUpperCase();

/// Avatar of [user] on the server of the [ApiRepository] in the widget tree
Widget lpsUserAvatar(BuildContext context, LpsUser user, {double size = 44}) =>
    D2Avatar.user(
      pictureUrl: context.read<ApiRepository>().avatarUrl(user),
      initials: nameInitial(user.name),
      size: size,
    );
