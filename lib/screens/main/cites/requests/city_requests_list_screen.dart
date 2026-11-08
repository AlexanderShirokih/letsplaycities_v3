import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_requests_bloc.dart';
import 'package:lets_play_cities/base/cities_list/city_item.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
import 'package:lets_play_cities/i18n/strings.g.dart';
import 'package:lets_play_cities/remote/city_requests_repository.dart';
import 'package:lets_play_cities/screens/common/d2/d2.dart';
import 'package:lets_play_cities/screens/common/error_texts.dart';
import 'package:shimmer/shimmer.dart';

import 'widget/request_item_card.dart';

/// Show a list of all (pending and approved) city editing requests
class CityRequestsListScreen extends StatelessWidget {
  const CityRequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final c = D2Colors.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            D2ScreenHeader(
              title: t.citiesRequest.listTitle,
              onBack: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: BlocProvider<CityRequestBloc>(
                create: (context) => CityRequestBloc(
                  GetIt.instance.get<CityRequestsRepository>(),
                  GetIt.instance.get<CountryRepository>(),
                ),
                child: Builder(
                  builder: (context) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<CityRequestBloc>().add(
                          CityRequestFetchData(),
                        );
                      },
                      child: BlocConsumer<CityRequestBloc, CityRequestState>(
                        listener: (context, state) {
                          if (state is NotAuthorizedError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.citiesRequest.signInToView),
                              ),
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
                                  style: D2Text.body.copyWith(color: c.ink),
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
                                    style: D2Text.section.copyWith(
                                      color: c.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 12.0),
                                  _createPendingRequests(context),
                                  const SizedBox(height: 28.0),
                                  Text(
                                    t.citiesRequest.reviewedTitle,
                                    style: D2Text.section.copyWith(
                                      color: c.ink,
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _createPendingRequests(BuildContext context) {
    return BlocBuilder<CityRequestBloc, CityRequestState>(
      builder: (context, state) {
        if (state is CityRequestInitial) {
          return Shimmer.fromColors(
            baseColor: D2Colors.of(context).edge,
            highlightColor: D2Colors.of(context).surface,
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
          return _showPendingItems(context, state.pendingItems);
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
            baseColor: D2Colors.of(context).edge,
            highlightColor: D2Colors.of(context).surface,
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
          return _showApprovedItems(context, state.approvedItems);
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
          _getErrorIcon(errorType, D2Colors.of(context).inkSoft),
          const SizedBox(height: 4.0),
          Text(
            context.t.citiesRequest.listLoadingError(message: message),
            style: D2Text.caption.copyWith(color: D2Colors.of(context).inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _getErrorIcon(_ErrorType errorType, Color color) {
    switch (errorType) {
      case _ErrorType.network:
        return D2Icon(D2Glyph.wifi, color: color);
      case _ErrorType.authorization:
        return D2Icon(D2Glyph.profile, color: color);
    }
  }

  Widget _showPendingItems(
    BuildContext context,
    List<CityPendingItem> pendingItems,
  ) {
    final t = context.t;
    final c = D2Colors.of(context);

    if (pendingItems.isEmpty) {
      return Center(
        child: Text(
          t.citiesRequest.noPending,
          style: D2Text.bodyRegular.copyWith(color: c.inkSoft),
        ),
      );
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
    BuildContext context,
    List<CityApprovedItem> approvedItems,
  ) {
    final t = context.t;
    final c = D2Colors.of(context);

    if (approvedItems.isEmpty) {
      return Center(
        child: Text(
          t.citiesRequest.noReviewed,
          style: D2Text.bodyRegular.copyWith(color: c.inkSoft),
        ),
      );
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
