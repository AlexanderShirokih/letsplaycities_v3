import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lets_play_cities/screens/common/utils.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_item.dart';

/// Shows card that describes approved or pending request
class RequestItemCard extends StatelessWidget {
  final RequestItemType cardType;
  final CityItem? from;
  final CityItem? to;
  final bool? isApproved;
  final String reason;
  final String result;

  const RequestItemCard({
    Key? key,
    required this.cardType,
    required this.reason,
    required this.result,
    this.isApproved,
    this.from,
    this.to,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 340.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 6.0,
            top: 6.0,
            right: 10.0,
            bottom: 10.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getItemTypeTitle(),
                    style: theme.textTheme.subtitle2
                        ?.copyWith(color: theme.hintColor),
                  ),
                  _createApprovalMark(),
                ],
              ),
              const SizedBox(height: 4.0),
              if (from != null) _createCityItem(context, from!),
              if (cardType == RequestItemType.Edit)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: FaIcon(
                        FontAwesomeIcons.exchangeAlt,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              if (to != null) ...[
                _createCityItem(context, to!),
                const SizedBox(height: 6.0),
              ],
              if (cardType == RequestItemType.Edit)
                const SizedBox(height: 12.0),
              if (reason.isNotEmpty)
                _createTextWithInlinedTitle(
                  context,
                  title: 'Причина:',
                  content: reason,
                ),
              if (result.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                _createTextWithInlinedTitle(
                  context,
                  title: 'Результат:',
                  content: result,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _createCityItem(BuildContext context, CityItem cityItem) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.onPrimary,
                style: BorderStyle.solid,
                width: 1.0,
              ),
            ),
            child: createFlagImage(cityItem.country.countryCode),
          ),
          const SizedBox(width: 7.0),
          Flexible(
            child: Text(
              cityItem.cityName,
              style: theme.textTheme.subtitle2,
              overflow: TextOverflow.fade,
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
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: content,
          )
        ],
      ),
      style: Theme.of(context).textTheme.caption,
    );
  }

  Widget _createApprovalMark() {
    final approved = isApproved;

    if (approved == null) {
      return const SizedBox();
    } else if (approved) {
      return FaIcon(FontAwesomeIcons.check, color: Colors.green);
    } else {
      return FaIcon(FontAwesomeIcons.times, color: Colors.red);
    }
  }

  String _getItemTypeTitle() {
    switch (cardType) {
      case RequestItemType.Edit:
        return 'Изменить';
      case RequestItemType.Add:
        return 'Добавить';
      case RequestItemType.Remove:
        return 'Удалить';
    }
  }
}

/// Describes card type
enum RequestItemType {
  Edit,
  Add,
  Remove,
}

/// Shows placeholder for request item card
class RequestItemCardShimmered extends StatelessWidget {
  final bool isApprovable;

  const RequestItemCardShimmered({
    Key? key,
    required this.isApprovable,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 340.0),
      child: Card(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 6.0,
            top: 6.0,
            right: 10.0,
            bottom: 10.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 65,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  if (isApprovable)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 4.0),
              _createCityItem(),
              const SizedBox(height: 12.0),
              Container(
                width: 197,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _createCityItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 23,
            height: 15,
            color: Colors.grey,
          ),
          const SizedBox(width: 8.0),
          Container(
            width: 197,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ],
      ),
    );
  }
}
