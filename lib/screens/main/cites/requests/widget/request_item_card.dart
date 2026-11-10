import 'package:flutter/material.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/game/cities_list.dart';

/// Shows card that describes approved or pending request
class RequestItemCard extends StatelessWidget {
  final RequestItemType cardType;
  final CityItem? from;
  final CityItem? to;
  final bool? isApproved;
  final String reason;
  final String result;

  /// Withdraws the request; `null` for a reviewed one, which has no button
  final VoidCallback? onWithdraw;

  const RequestItemCard({
    super.key,
    required this.cardType,
    required this.reason,
    required this.result,
    this.isApproved,
    this.from,
    this.to,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: D2Card(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 10),
              if (cardType == RequestItemType.edit)
                _editedCity(context)
              else if ((to ?? from) != null)
                _cityRow(context, (to ?? from)!),
              if (reason.isNotEmpty || result.isNotEmpty) ...[
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (reason.isNotEmpty) _note(c, null, reason),
                          if (reason.isNotEmpty && result.isNotEmpty)
                            const SizedBox(height: 6),
                          if (result.isNotEmpty)
                            _note(c, t.citiesRequest.resultLabel, result),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    // No icon: a plus or a pencil here looks like a button
    final label = switch (cardType) {
      RequestItemType.add => t.citiesRequest.typeAdd,
      RequestItemType.edit => t.citiesRequest.typeEdit,
      RequestItemType.remove => t.citiesRequest.typeRemove,
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: D2Text.small.copyWith(fontSize: 13, color: c.inkSoft),
            ),
          ),
          if (isApproved != null) ...[
            const SizedBox(width: 8),
            _statusPill(context, isApproved!),
          ],
          if (onWithdraw != null)
            TextButton(
              onPressed: onWithdraw,
              style: TextButton.styleFrom(
                foregroundColor: c.violet,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: D2Text.body.copyWith(fontSize: 14),
              ),
              child: Text(t.citiesRequest.withdraw),
            ),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context, bool approved) {
    final t = context.t;
    final c = D2Colors.of(context);
    // The error red is too dim as a text on a dark surface, so there the
    // pill is filled with it.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = approved
        ? c.ink
        : dark
        ? Colors.white
        : c.error;

    return Container(
      height: 26,
      padding: const EdgeInsets.fromLTRB(7, 0, 10, 0),
      decoration: BoxDecoration(
        color: approved
            ? c.mint.withValues(alpha: 0.25)
            : dark
            ? c.error
            : c.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          D2Icon(
            approved ? D2Glyph.check : D2Glyph.close,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            approved
                ? t.citiesRequest.statusApproved
                : t.citiesRequest.statusDeclined,
            style: D2Text.small.copyWith(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }

  /// City with its country; [strike] marks the name that is going away
  Widget _cityRow(
    BuildContext context,
    CityItem city, {
    bool strike = false,
    bool showCountry = true,
  }) {
    final c = D2Colors.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: Row(
        children: [
          CityFlag(city.country.countryCode, width: 28, height: 20, radius: 4),
          const SizedBox(width: 10),
          Expanded(
            // The smaller country stands on the baseline of the name
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    city.cityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        (strike
                                ? D2Text.bodyRegular.copyWith(fontSize: 16)
                                : D2Text.body)
                            .copyWith(
                              height: 1.25,
                              decoration: strike
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: strike ? c.inkSoft : c.ink,
                            ),
                  ),
                ),
                if (showCountry && city.country.name.isNotEmpty)
                  _countryName(c, city.country.name),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The country after the city name. Its width is capped, so a long city
  /// name gets the rest of the row instead of a half of it.
  Widget _countryName(D2Colors c, String name) => Padding(
    padding: const EdgeInsets.only(left: 10),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 110),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: D2Text.caption.copyWith(color: c.inkSoft),
      ),
    ),
  );

  /// Old name struck out, the new one under it
  Widget _editedCity(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);
    final old = from;
    final changed = to;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (old != null) _cityRow(context, old, strike: true),
        if (old != null && changed != null) const SizedBox(height: 2),
        if (changed != null)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              children: [
                Semantics(
                  label: t.citiesRequest.changesTo,
                  excludeSemantics: true,
                  child: SizedBox(
                    width: 28,
                    child: Center(
                      child: D2Icon(
                        D2Glyph.turnRight,
                        size: 20,
                        color: c.inkSoft,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          changed.cityName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: D2Text.body.copyWith(
                            height: 1.25,
                            color: c.ink,
                          ),
                        ),
                      ),
                      // The country is named again only when the request
                      // moves the city to another one.
                      if (old != null &&
                          changed.country.countryCode !=
                              old.country.countryCode &&
                          changed.country.name.isNotEmpty)
                        _countryName(c, changed.country.name),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _note(D2Colors c, String? label, String text) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label != null)
        Text(label, style: D2Text.small.copyWith(color: c.inkSoft)),
      Text(
        text,
        style: D2Text.bodyRegular.copyWith(
          fontSize: 14,
          height: 1.4,
          color: c.ink,
        ),
      ),
    ],
  );
}

/// Describes card type
enum RequestItemType { edit, add, remove }

/// Shows placeholder for request item card
class RequestItemCardShimmered extends StatelessWidget {
  final bool isApprovable;

  const RequestItemCardShimmered({super.key, required this.isApprovable});

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: D2Card(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 26,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _block(c, 90, 14),
                    if (isApprovable) _block(c, 84, 26, radius: 13),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _block(c, 28, 20),
                  const SizedBox(width: 10),
                  Flexible(child: _block(c, 160, 16)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                decoration: BoxDecoration(
                  color: c.edge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(c, 50, 10, color: c.surface),
                    const SizedBox(height: 6),
                    _block(c, 197, 14, color: c.surface),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(
    D2Colors c,
    double width,
    double height, {
    double radius = 4,
    Color? color,
  }) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color ?? c.edge,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
