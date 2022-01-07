import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_requests_bloc.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/screens/main/cites/model/city_item.dart';
import 'package:shimmer/shimmer.dart';

import 'widget/request_item_card.dart';

/// Show a list of all (pending and approved) city editing requests
class CityRequestsListScreen extends StatelessWidget {
  const CityRequestsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Заявки на измение города'),
      ),
      body: BlocProvider<CityRequestBloc>(
        create: (context) => CityRequestBloc(),
        child: Builder(builder: (context) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CityRequestBloc>().add(CityRequestFetchData());
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 26.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Заявки на рассмотрении',
                        style: theme.textTheme.headline6),
                    const SizedBox(height: 12.0),
                    _createPendingRequests(context),
                    const SizedBox(height: 28.0),
                    Text('Ранее рассмотренные заявки',
                        style: theme.textTheme.headline6),
                    const SizedBox(height: 12.0),
                    _createApprovedRequests(context),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _createPendingRequests(BuildContext context) {
    return BlocBuilder<CityRequestBloc, CityRequestState>(
      builder: (context, state) {
        if (state is CityRequestNoData) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            direction: ShimmerDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                3,
                (_) => RequestItemCardShimmered(
                  isApprovable: false,
                ),
              ),
            ),
          );
        } else if (state is CityRequestItems) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: state.pendingItems
                .map(
                  (e) => RequestItemCard(
                    cardType: _mapItemType(e.type),
                    reason: e.reason,
                    result: '',
                    from: _mapCityItem(e.source),
                    to: _mapCityItem(e.target),
                  ),
                )
                .toList(growable: false),
          );
        } else {
          return const Text('Что-то пошло не так');
        }
      },
    );
  }

  Widget _createApprovedRequests(BuildContext context) {
    return BlocBuilder<CityRequestBloc, CityRequestState>(
      builder: (context, state) {
        if (state is CityRequestNoData) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            direction: ShimmerDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                5,
                (_) => RequestItemCardShimmered(
                  isApprovable: true,
                ),
              ),
            ),
          );
        } else if (state is CityRequestItems) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: state.approvedItems
                .map(
                  (e) => RequestItemCard(
                    reason: e.reason,
                    result: e.result,
                    cardType: _mapItemType(e.type),
                    from: _mapCityItem(e.source),
                    to: _mapCityItem(e.target),
                    isApproved: e.isApproved,
                  ),
                )
                .toList(growable: false),
          );
        } else {
          return const Text('Что-то пошло не так');
        }
      },
    );
  }

  RequestItemType _mapItemType(CityRequestType type) {
    switch (type) {
      case CityRequestType.Add:
        return RequestItemType.Add;
      case CityRequestType.Edit:
        return RequestItemType.Edit;
      case CityRequestType.Remove:
        return RequestItemType.Remove;
    }
  }

  CityItem? _mapCityItem(CityRequestEntity? source) {
    if (source == null) return null;

    return CityItem(
      source.city,
      CountryEntity(
        source.countryName,
        source.countryCode,
        false,
      ),
    );
  }
}
