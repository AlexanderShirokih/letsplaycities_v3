import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/design/design.dart';
import 'package:lets_play_cities/screens/common/utils.dart';

/// Visas shown before the overflow tile
const passportVisaLimit = 11;

/// Tilts of the visa stamps, in degrees
const _tilts = [-6.0, 4.0, -3.0, 6.0, -5.0, 3.0];

/// Link-like button with an optional leading glyph, 44 px tall
class ProfileLink extends StatelessWidget {
  final String label;
  final AppGlyph? glyph;
  final VoidCallback onPressed;

  /// Text and glyph color, [AppColors.violet] by default
  final Color? color;

  const ProfileLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.glyph,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? AppColors.of(context).violet;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: label,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (glyph != null) ...[
                AppIcon(glyph!, size: 18, color: color),
                const SizedBox(width: 4),
              ],
              Text(label, style: AppText.small.copyWith(color: color)),
              if (glyph == null)
                RotatedBox(
                  quarterTurns: 2,
                  child: AppIcon(AppGlyph.back, size: 18, color: color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Countries the player named cities of, as visa stamps
class PassportCard extends StatelessWidget {
  /// Country codes, the most frequent first
  final List<int> countries;

  /// Country names by code
  final Map<int, String> names;

  const PassportCard({super.key, required this.countries, required this.names});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = AppColors.of(context);
    final shown = countries.take(passportVisaLimit).toList();
    final more = countries.length - shown.length;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // As tall as the «Все» link, also without it
          Row(
            children: [
              const SizedBox(height: 44),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    Text(
                      t.profile.passport,
                      style: AppText.section.copyWith(color: c.ink),
                    ),
                    Text(
                      t.profile.countriesCount(count: countries.length),
                      style: AppText.small.copyWith(
                        fontSize: 14,
                        color: c.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (countries.isNotEmpty)
                ProfileLink(
                  label: t.profile.all,
                  onPressed: () => _showAll(context),
                ),
            ],
          ),
          if (countries.isNotEmpty)
            GridView.count(
              crossAxisCount: 6,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final (i, code) in shown.indexed)
                  Center(
                    child: _Visa(
                      code: code,
                      index: i,
                      name: names[code] ?? '$code',
                    ),
                  ),
                if (more > 0) Center(child: _MoreTile(count: more)),
              ],
            ),
        ],
      ),
    );
  }

  void _showAll(BuildContext context) {
    showAppSheet<void>(
      context,
      builder: (_) => _AllCountries(countries: countries, names: names),
    );
  }
}

class _Visa extends StatelessWidget {
  final int code;
  final int index;
  final String name;

  const _Visa({required this.code, required this.index, required this.name});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = [c.violet, c.letter, c.error, c.inkSoft][index % 4];

    return Semantics(
      label: name,
      image: true,
      excludeSemantics: true,
      child: Transform.rotate(
        angle: _tilts[index % _tilts.length] * math.pi / 180,
        child: SizedBox.square(
          dimension: 40,
          child: CustomPaint(
            painter: _StampPainter(color, index % 3),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 16,
                child: FittedBox(child: createFlagImage(code)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stamp outline: a double ring, a double frame or a hexagon
class _StampPainter extends CustomPainter {
  final Color color;
  final int shape;

  const _StampPainter(this.color, this.shape);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final center = size.center(Offset.zero);

    switch (shape) {
      case 0:
        canvas.drawCircle(center, 18, stroke..strokeWidth = 2);
        canvas.drawCircle(center, 14, stroke..strokeWidth = 1.4);
      case 1:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 36, height: 28),
            const Radius.circular(6),
          ),
          stroke..strokeWidth = 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 29, height: 21),
            const Radius.circular(3),
          ),
          stroke..strokeWidth = 1.2,
        );
      default:
        final hexagon = Path()
          ..moveTo(20, 2)
          ..lineTo(36, 11)
          ..lineTo(36, 29)
          ..lineTo(20, 38)
          ..lineTo(4, 29)
          ..lineTo(4, 11)
          ..close();
        canvas.drawPath(hexagon, stroke..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(_StampPainter old) =>
      old.color != color || old.shape != shape;
}

class _MoreTile extends StatelessWidget {
  final int count;

  const _MoreTile({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      label: context.t.profile.moreCountries(count: count),
      excludeSemantics: true,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.edge, width: 2),
        ),
        child: Text('+$count', style: AppText.small.copyWith(color: c.violet)),
      ),
    );
  }
}

/// Every country, the most frequent first
class _AllCountries extends StatelessWidget {
  final List<int> countries;
  final Map<int, String> names;

  const _AllCountries({required this.countries, required this.names});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: countries.length,
      itemBuilder: (context, i) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              height: 24,
              child: FittedBox(child: createFlagImage(countries[i])),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                names[countries[i]] ?? '${countries[i]}',
                style: AppText.body.copyWith(color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
