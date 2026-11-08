import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_requests_bloc.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:shimmer/shimmer.dart';

import 'widget/request_item_card.dart';

/// Show a list of all (pending and approved) city editing requests
class CityRequestsListScreen extends StatelessWidget {
  const CityRequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.t;

    return Scaffold(
      appBar: AppBar(title: Text(t.citiesRequest.listTitle)),
      body: BlocProvider<CityRequestBloc>(
        create: (context) => CityRequestBloc(
          GetIt.instance.get<CityRequestsRepository>(),
          GetIt.instance.get<CountryRepository>(),
        ),
        child: Builder(
          builder: (context) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CityRequestBloc>().add(CityRequestFetchData());
              },
              child: BlocConsumer<CityRequestBloc, CityRequestState>(
                listener: (context, state) {
                  if (state is NotAuthorizedError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.citiesRequest.signInToView)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is CityRequestItems &&
                      state.pendingItems.isEmpty &&
                      state.approvedItems.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          t.citiesRequest.listEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26.0,
                        vertical: 32.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.citiesRequest.pendingTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12.0),
                          _createPendingRequests(context),
                          const SizedBox(height: 28.0),
                          Text(
                            t.citiesRequest.reviewedTitle,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12.0),
                          _createApprovedRequests(context),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _createPendingRequests(BuildContext context) {
    return BlocBuilder<CityRequestBloc, CityRequestState>(
      builder: (context, state) {
        if (state is CityRequestInitial) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            direction: ShimmerDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                3,
                (_) => RequestItemCardShimmered(isApprovable: false),
              ),
            ),
          );
        } else if (state is CityRequestItems) {
          return _showPendingItems(context.t, state.pendingItems);
        } else if (state is CityRequestError) {
          return _createLoadingError(
            context,
            _ErrorType.network,
            message: errorText(context.t, state.error),
          );
        } else if (state is NotAuthorizedError) {
          return _createLoadingError(context, _ErrorType.authorization);
        } else {
          return Text(context.t.citiesRequest.unexpectedState);
        }
      },
    );
  }

  Widget _createApprovedRequests(BuildContext context) {
    return BlocBuilder<CityRequestBloc, CityRequestState>(
      builder: (context, state) {
        if (state is CityRequestInitial) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            direction: ShimmerDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                5,
                (_) => RequestItemCardShimmered(isApprovable: true),
              ),
            ),
          );
        } else if (state is CityRequestItems) {
          return _showApprovedItems(context.t, state.approvedItems);
        } else if (state is CityRequestError) {
          return _createLoadingError(context, _ErrorType.network);
        } else if (state is NotAuthorizedError) {
          return _createLoadingError(context, _ErrorType.authorization);
        } else {
          return Text(
            context.t.citiesRequest.unexpectedStateDetails(state: state),
          );
        }
      },
    );
  }

  RequestItemType _mapItemType(CityRequestType type) {
    switch (type) {
      case CityRequestType.add:
        return RequestItemType.add;
      case CityRequestType.edit:
        return RequestItemType.edit;
      case CityRequestType.remove:
        return RequestItemType.remove;
    }
  }

  CityItem? _mapCityItem(CityRequestEntity? source) {
    if (source == null) return null;

    return CityItem(
      source.city,
      CountryEntity(source.countryName, source.countryCode, false),
    );
  }

  Widget _createLoadingError(
    BuildContext context,
    _ErrorType errorType, {
    String message = '',
  }) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getErrorIcon(errorType),
          const SizedBox(height: 4.0),
          Text(
            context.t.citiesRequest.listLoadingError(message: message),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _getErrorIcon(_ErrorType errorType) {
    switch (errorType) {
      case _ErrorType.network:
        return Icon(Icons.wifi_off);
      case _ErrorType.authorization:
        return Icon(Icons.no_accounts);
    }
  }

  Widget _showPendingItems(Translations t, List<CityPendingItem> pendingItems) {
    if (pendingItems.isEmpty) {
      return Center(child: Text(t.citiesRequest.noPending));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pendingItems
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
  }

  Widget _showApprovedItems(
    Translations t,
    List<CityApprovedItem> approvedItems,
  ) {
    if (approvedItems.isEmpty) {
      return Center(child: Text(t.citiesRequest.noReviewed));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: approvedItems
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
  }
}

enum _ErrorType { network, authorization }
