import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:lets_play_cities/base/cities_list/bloc/city_requests_bloc.dart';
import 'package:lets_play_cities/base/dictionary/country_entity.dart';
import 'package:lets_play_cities/base/repositories/cities/city_requests_repository.dart';
import 'package:lets_play_cities/base/repositories/cities/country_repository.dart';
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
        create: (context) => CityRequestBloc(
          GetIt.instance.get<CityRequestsRepository>(),
          GetIt.instance.get<CountryRepository>(),
        ),
        child: Builder(builder: (context) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CityRequestBloc>().add(CityRequestFetchData());
            },
            child: BlocConsumer<CityRequestBloc, CityRequestState>(
              listener: (context, state) {
                if (state is NotAuthorizedError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Для просмотра информации войдите в профиль'),
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
                        'Здесь пока ничего нет.\n'
                        'Вы можете самостоятельно отправлять заявки на изменение городов.\n'
                        'Мы обязательно рассмотрим вашу заявку. Свои заявки и результаты рассмотрения вы сможете увидеть здесь',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
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
                );
              },
            ),
          );
        }),
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
                (_) => RequestItemCardShimmered(
                  isApprovable: false,
                ),
              ),
            ),
          );
        } else if (state is CityRequestItems) {
          return _showPendingItems(state.pendingItems);
        } else if (state is CityRequestError) {
          return _createLoadingError(context, _ErrorType.Network,
              message: state.error);
        } else if (state is NotAuthorizedError) {
          return _createLoadingError(context, _ErrorType.Authorization);
        } else {
          return const Text('Что-то пошло не так');
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
                (_) => RequestItemCardShimmered(
                  isApprovable: true,
                ),
              ),
            ),
          );
        } else if (state is CityRequestItems) {
          return _showApprovedItems(state.approvedItems);
        } else if (state is CityRequestError) {
          return _createLoadingError(context, _ErrorType.Network);
        } else if (state is NotAuthorizedError) {
          return _createLoadingError(context, _ErrorType.Authorization);
        } else {
          return Text('Что-то пошло не так : $state');
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

  Widget _createLoadingError(
    BuildContext context,
    _ErrorType _errorType, {
    String message = '',
  }) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _getErrorIcon(_errorType),
          const SizedBox(height: 4.0),
          Text(
            'Не удалось загрузить данные :(\n$message',
            style: Theme.of(context).textTheme.caption,
          )
        ],
      ),
    );
  }

  Widget _getErrorIcon(_ErrorType errorType) {
    switch (errorType) {
      case _ErrorType.Network:
        return Icon(Icons.wifi_off);
      case _ErrorType.Authorization:
        return Icon(Icons.no_accounts);
    }
  }

  Widget _showPendingItems(List<CityPendingItem> pendingItems) {
    if (pendingItems.isEmpty) {
      return Center(
        child: Text('У вас нет открытых заявок'),
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

  Widget _showApprovedItems(List<CityApprovedItem> approvedItems) {
    if (approvedItems.isEmpty) {
      return Center(
        child: Text('У вас нет рассмотренных заявок'),
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

enum _ErrorType {
  Network,
  Authorization,
}
