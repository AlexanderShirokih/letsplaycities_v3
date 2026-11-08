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

  const RequestItemCard({
    super.key,
    required this.cardType,
    required this.reason,
    required this.result,
    this.isApproved,
    this.from,
    this.to,
  });

  @override
  Widget build(BuildContext context) {
    final c = D2Colors.of(context);
    final t = context.t;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 340.0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: D2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _getItemTypeTitle(t),
                      style: D2Text.small.copyWith(color: c.inkSoft),
                    ),
                  ),
                  _createApprovalMark(c),
                ],
              ),
              const SizedBox(height: 4.0),
              if (from != null) _createCityItem(context, from!),
              if (cardType == RequestItemType.edit)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: D2Icon(D2Glyph.send, size: 22, color: c.inkSoft),
                    ),
                  ),
                ),
              if (to != null) ...[
                _createCityItem(context, to!),
                const SizedBox(height: 6.0),
              ],
              if (cardType == RequestItemType.edit)
                const SizedBox(height: 12.0),
              if (reason.isNotEmpty)
                _createTextWithInlinedTitle(
                  context,
                  title: t.citiesRequest.reasonLabel,
                  content: reason,
                ),
              if (result.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                _createTextWithInlinedTitle(
                  context,
                  title: t.citiesRequest.resultLabel,
                  content: result,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _createCityItem(BuildContext context, CityItem cityItem) {
    final c = D2Colors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CityFlag(
            cityItem.country.countryCode,
            width: 28,
            height: 20,
            radius: 4,
          ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              cityItem.cityName,
              style: D2Text.body.copyWith(color: c.ink),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _createTextWithInlinedTitle(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final c = D2Colors.of(context);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title ',
            style: D2Text.body.copyWith(fontSize: 13, color: c.ink),
          ),
          TextSpan(text: content),
        ],
      ),
      style: D2Text.caption.copyWith(color: c.ink),
    );
  }

  Widget _createApprovalMark(D2Colors c) {
    final approved = isApproved;

    if (approved == null) {
      return const SizedBox();
    } else if (approved) {
      return D2Icon(D2Glyph.check, size: 22, color: c.mint);
    } else {
      return D2Icon(D2Glyph.close, size: 22, color: c.error);
    }
  }

  String _getItemTypeTitle(Translations t) {
    switch (cardType) {
      case RequestItemType.edit:
        return t.edit;
      case RequestItemType.add:
        return t.add;
      case RequestItemType.remove:
        return t.delete;
    }
  }
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

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 340.0),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: D2Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _block(c, 65, 12),
                  if (isApprovable) _block(c, 20, 20),
                ],
              ),
              const SizedBox(height: 4.0),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _block(c, 28, 20),
                    const SizedBox(width: 8.0),
                    Flexible(child: _block(c, 197, 16)),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              _block(c, 197, 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(D2Colors c, double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: c.edge,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
